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

# Get the client's public key
PUBLIC_KEY_FILE="${KEYS_DIR}/${CLIENT_NAME}_public.key"
if [ ! -f "$PUBLIC_KEY_FILE" ]; then
    echo "Error: Client $CLIENT_NAME not found (public key missing)"
    exit 1
fi

PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")

echo "===================================================================="
echo "Removing client $CLIENT_NAME from server configuration..."

# Create a backup
cp "$WG_CONF" "${WG_CONF}.backup"

# Use a simpler approach: recreate the entire config without the client
TEMP_FILE=$(mktemp)

# Read the original config and skip the peer section we want to remove
in_peer_to_remove=0
peer_lines=""

while IFS= read -r line; do
    # If we encounter a [Peer] line
    if [[ "$line" == "[Peer] #$CLIENT_NAME" ]]; then
        # If we were accumulating a peer, check if it's the one to remove
        if [[ -n "$peer_lines" ]]; then
            if [[ ! "$peer_lines" =~ "$PUBLIC_KEY" ]]; then
                # Not the peer to remove, so write it to the temp file
                echo "$peer_lines" >> "$TEMP_FILE"
            fi
        fi
        # Start new peer accumulation
        peer_lines="$line"
        in_peer_to_remove=0
    elif [[ -n "$peer_lines" ]]; then
        # We're accumulating a peer section
        peer_lines="$peer_lines"$'\n'"$line"
        
        # Check if this line contains the public key we're looking for
        if [[ "$line" == *"PublicKey = $PUBLIC_KEY"* ]]; then
            in_peer_to_remove=1
        fi
        
        # If we hit an empty line, it's the end of this peer section
        if [[ -z "$line" ]]; then
            if [[ $in_peer_to_remove -eq 0 ]]; then
                echo "$peer_lines" >> "$TEMP_FILE"
                echo >> "$TEMP_FILE"  # Add the empty line
            fi
            peer_lines=""
            in_peer_to_remove=0
        fi
    else
        # Not in a peer section, just copy the line
        echo "$line" >> "$TEMP_FILE"
    fi
done < "$WG_CONF"

# Handle the last peer section if the file doesn't end with a newline
if [[ -n "$peer_lines" ]]; then
    if [[ $in_peer_to_remove -eq 0 ]]; then
        echo "$peer_lines" >> "$TEMP_FILE"
    fi
fi

# Replace the original config
mv "$TEMP_FILE" "$WG_CONF"

# Remove client keys and config
echo "Removing client keys and configuration..."
rm -f "${KEYS_DIR}/${CLIENT_NAME}_private.key"
rm -f "${KEYS_DIR}/${CLIENT_NAME}_public.key"
rm -f "${CONFIGS_DIR}/${CLIENT_NAME}.conf"

# Reload WireGuard configuration
echo "Reloading WireGuard configuration..."
wg syncconf wg0 <(wg-quick strip wg0)

echo "Client ${CLIENT_NAME} removed successfully!"
echo "===================================================================="
