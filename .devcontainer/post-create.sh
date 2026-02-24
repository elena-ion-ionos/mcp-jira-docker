#!/bin/bash
set -euo pipefail

export PATH="/usr/local/bin:/home/node/.local/bin:/home/node/.cargo/bin:/usr/local/share/npm-global/bin:$PATH"

# ── 1. Ensure uvx is available ─────────────────────────────────────────────
if ! which uvx > /dev/null 2>&1; then
  echo "[post-create] uvx not found in image, installing from GitHub releases..."
  mkdir -p /home/node/.local/bin
  ARCH=$(uname -m)
  curl -fsSL "https://github.com/astral-sh/uv/releases/latest/download/uv-${ARCH}-unknown-linux-gnu.tar.gz" \
    | tar -xz --strip-components=1 -C /home/node/.local/bin/
  # Symlink into /usr/local/bin so Claude's restricted PATH can find them
  echo "[post-create] Symlinking uv/uvx to /usr/local/bin..."
  sudo ln -sf /home/node/.local/bin/uvx /usr/local/bin/uvx
  sudo ln -sf /home/node/.local/bin/uv /usr/local/bin/uv
fi

export PATH="/home/node/.local/bin:$PATH"
echo "[post-create] uvx version: $(uvx --version)"

# ── 2. Create a pip shim via uv (pip is not installed in base image) ───────
if ! which pip > /dev/null 2>&1; then
  echo "[post-create] Creating pip shim..."
  mkdir -p /home/node/.local/bin
  printf '#!/bin/sh\nexec uv pip "$@"\n' > /home/node/.local/bin/pip
  chmod +x /home/node/.local/bin/pip
fi
echo "[post-create] pip version: $(pip --version)"

# ── 3. MCP server config is defined in /workspace/.mcp.json ──
# atlassian-local connects via SSE to host.docker.internal:9000
echo "[post-create] MCP config is in /workspace/.mcp.json (SSE via host)"

echo "[post-create] Done."

