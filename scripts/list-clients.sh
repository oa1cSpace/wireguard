#!/bin/bash

CONFIGS_DIR="/wg/configs"

echo "============================================="
echo "Connected clients:"
echo "============================================="
wg show wg0 peers | while read peer; do
    latest_handshake=$(wg show wg0 latest-handshakes | grep "$peer" | awk '{print $2}')
    transfer=$(wg show wg0 transfer | grep "$peer" | awk '{print $2 " received, " $3 " sent"}')
    
    if [ -n "$latest_handshake" ] && [ "$latest_handshake" -gt 0 ]; then
        handshake_time=$(date -d "@$latest_handshake" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "N/A")
        echo "Peer: $(echo $peer | cut -c1-16)..."
        echo "  Last handshake: $handshake_time"
        echo "  Transfer: $transfer"
        echo ""
    fi
done
echo "---------------------------------------------"

echo "============================================="
echo "Available client configurations:"
echo "============================================="
ls -1 "${CONFIGS_DIR}"/*.conf 2>/dev/null | while read config; do
    echo "  $(basename "$config" .conf)"
done
echo "---------------------------------------------"