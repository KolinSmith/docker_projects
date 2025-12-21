# Tor Middle Relay

This is a Docker Compose configuration for running a Tor middle relay, migrated from the operator server.

## Configuration

- **Nickname**: operaTor
- **Type**: Middle relay (no exit traffic)
- **ORPort**: 8443
- **DirPort**: 8444
- **Bandwidth**: 1MB/s throttled, 1.5MB/s burst
- **Memory**: ~600MB typical usage, 1GB limit

## Current Status (on operator)

- Running since: 2025-11-20
- Process memory: ~602MB RSS
- Data directory size: ~232MB
- Keys and fingerprints preserved in /var/lib/tor/

## Deployment

```bash
# Start the relay
docker-compose up -d

# View logs
docker-compose logs -f tor-relay

# Check status
docker-compose ps

# Stop the relay
docker-compose down
```

## Migration Notes

To migrate from the existing operator server:

1. Backup the Tor data directory from operator:
   ```bash
   operator "sudo tar -czf /tmp/tor-backup.tar.gz -C /var/lib/tor ."
   scp operator:/tmp/tor-backup.tar.gz ./tor-data-backup.tar.gz
   ```

2. Extract to the Docker volume:
   ```bash
   docker-compose up -d
   docker-compose down
   docker run --rm -v tor_relay_tor_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/tor-data-backup.tar.gz"
   ```

3. Ensure proper permissions:
   ```bash
   docker-compose run --rm tor-relay chown -R debian-tor:debian-tor /var/lib/tor
   ```

4. Start the relay:
   ```bash
   docker-compose up -d
   ```

## Monitoring

- Check relay status: https://metrics.torproject.org/rs.html
- Search for relay by nickname: "operaTor"
- View logs: `docker-compose logs -f`

## Security Notes

- This is a **middle relay**, not an exit node
- No exit traffic is allowed (ExitPolicy reject *:*)
- Minimal attack surface
- Isolated in Docker network
