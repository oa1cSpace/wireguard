#!/bin/bash

set -e

WG_DIR="/etc/wireguard"
WG_CONF="${WG_DIR}/wg0.conf"
KEYS_DIR="/wg/keys"
CONFIGS_DIR="/wg/configs"

# Generate server keys if they don't exist
if [ ! -f "${KEYS_DIR}/server_private.key" ]; then
    echo "============================================="
    echo "Generating server keys..."
    echo "============================================="
    umask 077
    wg genkey | tee "${KEYS_DIR}/server_private.key" | wg pubkey > "${KEYS_DIR}/server_public.key"
fi

# Create WireGuard configuration
if [ ! -f "${WG_CONF}" ]; then
    echo "============================================="
    echo "Creating WireGuard configuration..."
    echo "============================================="
    cat > "${WG_CONF}" << EOF
[Interface]
PrivateKey = $(cat "${KEYS_DIR}/server_private.key")
Address = 10.8.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

EOF
fi
# Start WireGuard
echo "Starting WireGuard..."
wg-quick up wg0

# Keep container running
echo "============================================="
echo "WireGuard is running..."
echo "============================================="
while true; do
    sleep 3600
done
