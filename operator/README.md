# Operator Services

Docker Compose stack for the Operator server (Orange Pi R1 Plus LTS) running:
- **Tor Relay** - Tor middle relay / guard node
- **Beszel Agent** - System monitoring agent

## Services

### Tor Relay
Tor middle relay that may be promoted to Guard status after ~8 days of stable operation.

- **Image**: `ghcr.io/kolinsmith/tor-relay-docker:latest`
- **Ports**: 8443 (ORPort), 8444 (DirPort)
- **Memory**: 1GB limit, 512MB reserved
- **Config**: `torrc` file (already configured for operaTor relay)
- **Docs**: https://github.com/KolinSmith/tor-relay-docker

### Beszel Agent
Lightweight system monitoring agent that reports to Beszel hub.

- **Image**: `henrygd/beszel-agent:latest`
- **Port**: 45876 (SSH for hub connection)
- **Memory**: 128MB limit
- **Config**: Requires `BESZEL_AGENT_KEY` in `.env`

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Firewall ports 8443 and 8444 open (for Tor relay)
- Beszel hub running and accessible

### Setup

1. **Create environment file**:
   ```bash
   cp .env.example .env
   # Edit .env and set BESZEL_AGENT_KEY from Beszel web UI
   ```

2. **Start services**:
   ```bash
   docker compose up -d
   ```

3. **Check logs**:
   ```bash
   # Tor relay logs
   docker compose logs -f tor-relay

   # Beszel agent logs
   docker compose logs -f beszel-agent
   ```

## Monitoring Tor Relay

### Check Relay on Tor Network

Visit [Tor Metrics Relay Search](https://metrics.torproject.org/rs.html#search) to find your relay:
- Search by nickname: `operaTor`
- Search by contact email

**Note**: New relays appear within 24-48 hours. Guard promotion takes ~8 days of stable operation.

## Managing Services

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Update images
docker compose pull
docker compose up -d
```

## Volumes

- `tor_data` - Tor relay keys and state (preserve to maintain relay identity)
- `tor_logs` - Tor log files
- `beszel_agent_data` - Beszel agent data

**Important**: The `tor_data` volume contains your relay's cryptographic identity. Do not delete this volume or your relay will lose its reputation and fingerprint.

## Migration from Native Tor

When migrating from native Tor installation to Docker:

1. Stop native Tor: `sudo systemctl stop tor`
2. Copy identity keys from `/var/lib/tor/` to the `tor_data` volume
3. Disable native Tor: `sudo systemctl disable tor`
4. Start Docker stack: `docker compose up -d`

## Resources

- **Tor Relay Guide**: https://community.torproject.org/relay/
- **Tor Metrics**: https://metrics.torproject.org/
- **Beszel**: https://github.com/henrygd/beszel
- **Tor Relay Docker**: https://github.com/KolinSmith/tor-relay-docker
