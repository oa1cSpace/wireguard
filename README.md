![alt text](https://www.wireguard.com/img/wireguard.svg)
# Multi-Platform VPN Server

A production-ready Dockerized VPN server supporting both ```amd64``` and ```arm64``` architectures with simple user management.

[WireGuard official website](https://www.wireguard.com/)

## Features

- 🐳 Docker multi-platform support (amd64, arm64)
- 🔐 Simple client management
- 📱 QR code generation for mobile clients
- 🔄 Hot-reload client configurations
- 🛡️ Production-ready with proper security
- 📊 Client connection monitoring
- 🔌 IPv4 only (no IPv6 complexity)

## Quick Start

### Prerequisites:

- Docker and Docker Compose
- A server with a public IP address
- UDP port 51820 open in firewall

### Installation

1. **Clone and setup:**
```bash
git clone https://github.com/oa1cSpace/wireguard
cd wireguard
mkdir -p data/{wireguard,keys,configs}
chmod +x scripts/*.sh
```

2. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with your server details
nano .env
```

3. **Build and start:**
```bash
docker compose -f wireguard-compose.yml up -d --build
```

or just use lates image ```image: soer42/wireguard:latest```, and run:
```bash
docker compose -f wireguard-compose.yml up -d
```

4. **Add your first client:**
```bash
docker exec -it wireguard /usr/local/bin/add-client.sh my-laptop
```

## File Structure

```
wireguard-vpn/
├── Dockerfile
├── wireguard-compose.yml
├── .env
├── scripts/
│   ├── start-wg.sh
│   ├── add-client.sh
│   ├── remove-client.sh
│   └── list-clients.sh
└── data/
    ├── wireguard/     # Server configuration
    ├── keys/          # Public/private keys
    └── configs/       # Client configuration files
```

## Client Management

### Adding a Client
```bash
docker exec -it wireguard /usr/local/bin/add-client.sh client-name
```

This will:
- Generate client keys
- Assign the next available IP (10.0.0.2, 10.0.0.3, etc.)
- Create client configuration file
- Display QR code for mobile devices

### Removing a Client
```bash
docker exec -it wireguard /usr/local/bin/remove-client.sh client-name
```

### Listing Clients
```bash
docker exec -it wireguard /usr/local/bin/list-clients.sh
```

### Example Workflow
```bash
# Add three clients
docker exec -it wireguard add-client.sh laptop
docker exec -it wireguard add-client.sh phone
docker exec -it wireguard add-client.sh tablet

# List all clients and their status
docker exec -it wireguard list-clients.sh

# Remove a client
docker exec -it wireguard remove-client.sh tablet
```

## Network Configuration

- **VPN Network:** `10.0.0.0/24`
- **Server IP:** `10.0.0.1`
- **Client IP Range:** `10.0.0.2` - `10.0.0.253`
- **Port:** `51820/udp`
- **DNS:** `8.8.8.8, 1.1.1.1` (Google and Cloudflare)

## Client Configuration

### Mobile Clients (QR Code)
1. Install WireGuard app from App Store/Play Store
2. Tap "+" and select "Create from QR code"
3. Scan the QR code displayed when adding a client

### Desktop Clients
1. Copy the generated `.conf` file from `data/configs/client-name.conf`
2. Import into WireGuard client
3. Activate the tunnel

### Manual Configuration Example
The generated client config looks like:
```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/32
DNS = 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## Server Management

### View Server Status
```bash
docker exec -it wireguard wg show
```

### View Container Logs
```bash
docker logs wireguard
```

### Stop Service
```bash
docker-compose -f wireguard-compose.yml down
```

### Restart Service
```bash
docker-compose -f wireguard-compose.yml restart
```

### Update and Rebuild
```bash
docker-compose -f wireguard-compose.yml down
docker-compose -f wireguard-compose.yml up -d --build
```

## Environment Configuration

Edit the `.env` file to match your setup:

```bash
# Server public address (domain or IP)
WG_HOST=your-server-domain.com

# WireGuard port
WG_PORT=51820

# VPN network
WG_NETWORK=10.0.0.0/24

# Client routing (0.0.0.0/0 for all traffic)
WG_ALLOWED_IPS=0.0.0.0/0

# Keepalive interval
WG_PERSISTENT_KEEPALIVE=25
```

## Security Best Practices

1. **Firewall Configuration:**
```bash
# Allow WireGuard port only
ufw allow 51820/udp
ufw enable
```

2. **System Configuration:**
```bash
# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p
```

3. **Key Security:**
   - Private keys are stored in `data/keys/` with 600 permissions
   - Never commit keys to version control
   - Regularly rotate keys for sensitive clients

4. **Network Security:**
   - Clients only see traffic routed through VPN
   - Use split tunneling by modifying `WG_ALLOWED_IPS` if needed

## Troubleshooting

### Client Cannot Connect
1. **Check port accessibility:**
```bash
nc -u -v your-server.com 51820
```

2. **Verify server configuration:**
```bash
docker exec -it wireguard wg show
```

3. **Check client IP assignment:**
   - Ensure client IP is in 10.0.0.2-10.0.0.253 range
   - No IP conflicts

4. **Inspect logs:**
```bash
docker logs wireguard
```

### Performance Issues
1. **Check server resources:**
```bash
docker stats wireguard
```

2. **Monitor network:**
```bash
docker exec -it wireguard wg show
```

### Configuration Issues
1. **Reset and rebuild:**
```bash
docker-compose -f wireguard-compose.yml down
docker-compose -f wireguard-compose.yml up -d --build
```

2. **Check file permissions:**
```bash
chmod 600 data/keys/*
chmod 644 data/configs/*.conf
```

## Backup and Restore

### Backup Configuration
```bash
# Backup all data
tar czf wireguard-backup-$(date +%Y%m%d).tar.gz data/

# Backup only keys and configs (recommended)
tar czf wireguard-keys-configs-$(date +%Y%m%d).tar.gz data/keys/ data/configs/
```

### Restore from Backup
```bash
# Stop service
docker-compose -f wireguard-compose.yml down

# Restore data
tar xzf wireguard-backup-YYYYMMDD.tar.gz

# Restart service
docker-compose -f wireguard-compose.yml up -d
```

## Multi-Platform Support

This setup supports both amd64 and arm64 architectures. The Docker image automatically uses the correct architecture for your system.

To explicitly build for multiple platforms:

```bash
# Set up buildx
docker buildx create --use

# Build for both architectures
docker buildx build --platform linux/amd64,linux/arm64 -t your-registry/wireguard:latest .
docker buildx build --platform linux/amd64,linux/arm64 -t your-registry/wireguard:latest . --load
docker buildx build --platform linux/amd64,linux/arm64 -t your-registry/wireguard:latest . --push
```

## Monitoring and Maintenance

### Regular Maintenance Tasks
1. **Update containers:**
```bash
docker-compose -f wireguard-compose.yml pull
```

2. **Check client activity:**
```bash
docker exec -it wireguard list-clients.sh
```

3. **Remove inactive clients:**
```bash
docker exec -it wireguard remove-client.sh old-client
```

## License

MIT License - feel free to modify and distribute.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Verify your server's firewall settings
3. Ensure the ```UDP``` port ```51820``` is accessible
4. Check Docker and Docker Compose versions

---

**Important:** Remember to set `WG_HOST` in your `.env` file to your server's public IP or domain name before starting the service.

**Note:** This setup uses IPv4 only as requested. The VPN network is 10.0.0.0/24 with the server at 10.0.0.1 and clients from 10.0.0.2 to 10.0.0.253.
