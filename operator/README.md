# Operator Services

Docker Compose stack for the Operator server running:
- **Capture** - System monitoring and capture tool
- **Tor Relay** - Tor middle relay / guard node

## Services

### Capture
Lightweight system monitoring service from Bluewave Labs.

- **Image**: `ghcr.io/bluewave-labs/capture:latest`
- **Port**: Uses host network mode
- **Memory**: 128MB limit
- **Config**: Requires `CAPTURE_API_SECRET` in `.env`

### Tor Relay
Tor middle relay that may be promoted to Guard status after ~8 days of stable operation.

- **Image**: `ghcr.io/kolinsmith/tor-relay-docker:latest`
- **Ports**: 8443 (ORPort), 8444 (DirPort)
- **Memory**: 1GB limit, 512MB reserved
- **Config**: Edit `torrc` to set relay nickname and contact info
- **Docs**: https://github.com/KolinSmith/tor-relay-docker

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Firewall ports 8443 and 8444 open (for Tor relay)

### Setup

1. **Create environment file**:
   ```bash
   cp .env.example .env
   # Edit .env and set CAPTURE_API_SECRET
   ```

2. **Configure Tor relay**:
   ```bash
   # Edit torrc and set your relay nickname and contact email
   nano torrc
   ```

   **Required changes**:
   - `Nickname YourRelayNickname` → Set your unique relay name
   - `ContactInfo your-email@example.com` → Set your contact email

3. **Start services**:
   ```bash
   docker-compose up -d
   ```

4. **Check logs**:
   ```bash
   # Capture logs
   docker-compose logs -f capture

   # Tor relay logs
   docker-compose logs -f tor-relay
   ```

## Monitoring Tor Relay

### Interactive Monitoring with Nyx

Install nyx on the host:
```bash
sudo apt install nyx
```

Create an alias for easy monitoring:
```bash
# Add to ~/.bashrc or ~/.bash_aliases
alias status='docker exec -it tor-relay sudo -u debian-tor nyx'
```

Then run: `status`

### Check Relay on Tor Network

Visit [Tor Metrics Relay Search](https://metrics.torproject.org/rs.html#search) to find your relay:
- Search by relay nickname
- Search by contact email
- Search by fingerprint

**Note**: New relays appear within 24-48 hours. Guard promotion takes ~8 days of stable operation.

## Managing Services

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f tor-relay
docker-compose logs -f capture
```

### Restart services
```bash
# All services
docker-compose restart

# Specific service
docker-compose restart tor-relay
```

### Stop services
```bash
docker-compose down
```

### Update images
```bash
docker-compose pull
docker-compose up -d
```

## Configuration

### Capture
- Set `CAPTURE_API_SECRET` in `.env` file
- Memory limit: 128MB

### Tor Relay
- **Primary config**: Edit `torrc` file
- **Optional env vars**: Can override torrc settings in `.env`
- **Ports**: Customize via `TOR_OR_PORT` and `TOR_DIR_PORT` env vars
- **Memory limit**: 1GB (sufficient for middle relay/guard)

### Exit Relay Configuration
If you want to run an exit relay instead of a middle relay, see the comprehensive guide:
https://github.com/KolinSmith/tor-relay-docker#exit-relay-configuration

## Volumes

- `tor_data` - Tor relay keys and state (preserve to maintain relay identity)
- `tor_logs` - Tor log files

**Important**: The `tor_data` volume contains your relay's cryptographic identity. Do not delete this volume or your relay will lose its reputation and fingerprint.

## Resources

- **Tor Relay Guide**: https://community.torproject.org/relay/
- **Tor Metrics**: https://metrics.torproject.org/
- **Capture Project**: https://github.com/bluewave-labs/capture
- **Tor Relay Docker**: https://github.com/KolinSmith/tor-relay-docker
