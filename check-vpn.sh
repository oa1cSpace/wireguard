#!/bin/bash
echo "=== WireGuard Status ==="
docker exec wireguard wg show
echo -e "\n=== Connected Clients ==="
docker exec wireguard list-clients.sh
