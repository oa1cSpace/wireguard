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
WG_HOST="${WG_HOST:-your-server-domain.com}"
WG_PORT="${WG_PORT:-51820}"
WG_ALLOWED_IPS="${WG_ALLOWED_IPS:-0.0.0.0/0}"
WG_PERSISTENT_KEEPALIVE="${WG_PERSISTENT_KEEPALIVE:-25}"

# Get the client's public key
PUBLIC_KEY_FILE="${KEYS_DIR}/${CLIENT_NAME}_public.key"
if [ -f "$PUBLIC_KEY_FILE" ]; then
    echo "Error: Client $CLIENT_NAME already exists"
    exit 1
fi

# Generate client keys
echo "================================================"
echo "Generating keys for client: $CLIENT_NAME"
umask 077
wg genkey | tee "${KEYS_DIR}/${CLIENT_NAME}_private.key" | wg pubkey > "${KEYS_DIR}/${CLIENT_NAME}_public.key"

# Get the next available IP
LAST_IP=$(grep "Address" "${WG_CONF}" | tail -1 | awk '{print $3}' | cut -d'.' -f4 | cut -d'/' -f1 2>/dev/null || echo "1")
NEXT_IP=$((LAST_IP + 1))

if [ $NEXT_IP -ge 254 ]; then
    echo "======================================================="
    echo "  Error: No more available IP addresses in the subnet"
    echo "======================================================="
    exit 1
fi

CLIENT_IP="10.8.0.${NEXT_IP}/32"

# Add client to server configuration
echo "Adding client to server configuration..."
cat >> "${WG_CONF}" << EOF

[Peer] #$CLIENT_NAME
PublicKey = $(cat "${KEYS_DIR}/${CLIENT_NAME}_public.key")
AllowedIPs = ${CLIENT_IP}
EOF

# Create client configuration
echo "Creating client configuration..."
CLIENT_CONFIG="${CONFIGS_DIR}/${CLIENT_NAME}.conf"
cat > "${CLIENT_CONFIG}" << EOF
[Interface]
PrivateKey = $(cat "${KEYS_DIR}/${CLIENT_NAME}_private.key")
Address = ${CLIENT_IP}
DNS = 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = $(cat "${KEYS_DIR}/server_public.key")
Endpoint = ${WG_HOST}:${WG_PORT}
AllowedIPs = ${WG_ALLOWED_IPS}
PersistentKeepalive = ${WG_PERSISTENT_KEEPALIVE}
EOF

# Reload WireGuard configuration
echo "Reloading WireGuard configuration..."
wg syncconf wg0 <(wg-quick strip wg0)

echo "================================================"
echo "Client ${CLIENT_NAME} added successfully!"
echo "Client IP: ${CLIENT_IP}"
echo "Configuration file: ${CONFIGS_DIR}/${CLIENT_NAME}.conf"
echo ""
echo "To generate QR code, run on your host machine:"
echo "  qrencode -t ansiutf8 < data/configs/${CLIENT_NAME}.conf"
echo ""
echo "Or import the file directly from:"
echo "  data/configs/${CLIENT_NAME}.conf"
echo "================================================"
