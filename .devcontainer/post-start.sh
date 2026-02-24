#!/bin/bash
# Runs on every container start (postStartCommand)
# 1. Initialise the outbound firewall (whitelist-only)
# 2. Verify the MCP Atlassian SSE endpoint is reachable

echo "[post-start] Initialising firewall..."
sudo /usr/local/bin/init-firewall.sh
echo "[post-start] Firewall initialised ✓"

MCP_HOST="${MCP_ATLASSIAN_URL:-http://mcp-atlassian:${MCP_ATLASSIAN_PORT:-9000}}"

echo "[post-start] Checking MCP Atlassian SSE endpoint at $MCP_HOST/sse ..."
for i in 1 2 3 4 5; do
    if curl -sf --max-time 3 "$MCP_HOST/sse" -o /dev/null; then
        echo "[post-start] MCP Atlassian SSE is reachable ✓"
        break
    fi
    echo "[post-start] Waiting for MCP server... (attempt $i/5)"
    sleep 2
done

echo "[post-start] Done."
