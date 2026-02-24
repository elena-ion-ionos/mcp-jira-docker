#!/bin/sh
# Runs inside fw-init container (network_mode: host, privileged)
# Adds iptables INPUT rules for every 172.x Docker bridge subnet

PORT="${MCP_ATLASSIAN_PORT:-9000}"

echo "[fw-init] Allowing Docker bridge subnets to reach port $PORT..."

# Find all 172.x subnets on host interfaces
ip -o -f inet addr show | awk '{print $4}' | grep '^172\.' | while read -r SUBNET; do
    echo "[fw-init] Processing $SUBNET..."
    if iptables -C INPUT -s "$SUBNET" -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
        echo "[fw-init] Rule already exists for $SUBNET — skipping"
    else
        iptables -I INPUT -s "$SUBNET" -p tcp --dport "$PORT" -j ACCEPT
        echo "[fw-init] Rule added for $SUBNET"
    fi
done

echo "[fw-init] Done."