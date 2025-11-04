#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <client_name>"
    exit 1
fi

CLIENT_NAME="$1"
KEYS_DIR="/wg/keys"
CONFIGS_DIR="/wg/configs"
WG_CONF="/etc/wireguard/wg0.conf"

# Remove client from server configuration
echo "============================================="
echo "Removing client $CLIENT_NAME from server configuration..."
echo "============================================="
sed -i "/### BEGIN CLIENT ${CLIENT_NAME} ###/,/### END CLIENT ${CLIENT_NAME} ###/d" "${WG_CONF}" 2>/dev/null || true

# Alternative removal method if the above doesn't work
PUBLIC_KEY_FILE="${KEYS_DIR}/${CLIENT_NAME}_public.key"
if [ -f "$PUBLIC_KEY_FILE" ]; then
    PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")
    sed -i "/PublicKey = ${PUBLIC_KEY}/,/AllowedIPs = 10.8.0.*\/32/d" "${WG_CONF}"
fi

# Remove client keys and config
echo "============================================="
echo "Removing client keys and configuration..."
echo "============================================="
rm -f "${KEYS_DIR}/${CLIENT_NAME}_private.key"
rm -f "${KEYS_DIR}/${CLIENT_NAME}_public.key"
rm -f "${CONFIGS_DIR}/${CLIENT_NAME}.conf"

# Reload WireGuard configuration
echo "============================================="
echo "Reloading WireGuard configuration..."
echo "============================================="
wg syncconf wg0 <(wg-quick strip wg0)

echo "============================================="
echo "Client ${CLIENT_NAME} removed successfully!"
echo "============================================="
