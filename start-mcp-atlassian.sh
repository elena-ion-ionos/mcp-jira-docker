#!/bin/bash
# ============================================================
# start-mcp-atlassian.sh
# Run this on the HOST before / when starting the dev container.
# Reads credentials from mcp-atlassian/.env and launches
# mcp-atlassian as a daemonised SSE server on port 9000.
#
# Called automatically by devcontainer initializeCommand.
# Safe to call multiple times – skips if already running.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
PID_FILE="/tmp/mcp-atlassian.pid"
LOG_FILE="/tmp/mcp-atlassian.log"

# ── 0. Skip if already running ───────────────────────────────────────────────
if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[mcp-atlassian] Already running (PID $PID) – skipping."
    exit 0
  fi
  rm -f "$PID_FILE"
fi

# ── 1. Load .env ─────────────────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
  echo "[mcp-atlassian] ERROR: .env file not found at $ENV_FILE" >&2
  exit 1
fi

echo "[mcp-atlassian] Loading environment from $ENV_FILE..."
set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

# Validate required vars
for var in JIRA_URL JIRA_PERSONAL_TOKEN CONFLUENCE_URL CONFLUENCE_PERSONAL_TOKEN; do
  if [ -z "${!var:-}" ]; then
    echo "[mcp-atlassian] ERROR: $var is not set in $ENV_FILE" >&2
    exit 1
  fi
done

PORT="${MCP_ATLASSIAN_PORT:-9000}"

# ── 2. Ensure uv / uvx is installed ──────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

install_uv() {
  echo "[mcp-atlassian] Installing uv (includes uvx)..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
}

if ! command -v uvx &>/dev/null; then
  install_uv
fi

echo "[mcp-atlassian] uvx version: $(uvx --version 2>&1 || echo 'unknown')"

# ── 3. Kill any existing instance on the same port ───────────────────────────
if command -v lsof &>/dev/null && lsof -ti tcp:"$PORT" &>/dev/null; then
  echo "[mcp-atlassian] Stopping existing process on port $PORT..."
  lsof -ti tcp:"$PORT" | xargs kill -9 2>/dev/null || true
  sleep 1
fi

# ── 4. Launch as a fully detached daemon ─────────────────────────────────────
echo "[mcp-atlassian] Starting SSE server on 0.0.0.0:$PORT (log: $LOG_FILE)..."
echo "[mcp-atlassian] JIRA_URL=$JIRA_URL"
echo "[mcp-atlassian] CONFLUENCE_URL=$CONFLUENCE_URL"

setsid uvx mcp-atlassian \
  --transport sse \
  --port "$PORT" \
  --host 0.0.0.0 \
  >> "$LOG_FILE" 2>&1 &

DAEMON_PID=$!
echo "$DAEMON_PID" > "$PID_FILE"
echo "[mcp-atlassian] Started with PID $DAEMON_PID. Log: $LOG_FILE"

sleep 2
if kill -0 "$DAEMON_PID" 2>/dev/null; then
  echo "[mcp-atlassian] Server is running OK."
else
  echo "[mcp-atlassian] ERROR: Server failed to start. Check $LOG_FILE" >&2
  cat "$LOG_FILE" >&2
  exit 1
fi

# ── 5. Allow all Docker bridge networks to reach the SSE port ────────────────
echo "[mcp-atlassian] Configuring iptables for Docker bridge networks..."

# Get all active Docker bridge network subnets dynamically
DOCKER_SUBNETS=$(docker network ls -q | xargs docker network inspect \
  --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null | grep -v '^$')

if [ -z "$DOCKER_SUBNETS" ]; then
  echo "[mcp-atlassian] WARNING: No Docker subnets found, falling back to 172.16.0.0/12"
  DOCKER_SUBNETS="172.16.0.0/12"
fi

while read -r subnet; do
  # Skip if rule already exists
  if sudo iptables -C INPUT -s "$subnet" -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
    echo "[mcp-atlassian] iptables rule already exists for $subnet – skipping."
  else
    if sudo iptables -I INPUT -s "$subnet" -p tcp --dport "$PORT" -j ACCEPT; then
      echo "[mcp-atlassian] iptables rule added for $subnet → port $PORT"
    else
      echo "[mcp-atlassian] WARNING: Failed to add iptables rule for $subnet" >&2
    fi
  fi
done <<< "$DOCKER_SUBNETS"