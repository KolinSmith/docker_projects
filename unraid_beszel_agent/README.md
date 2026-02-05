# Unraid Docker Compose Stack

Complete Unraid media server and monitoring stack with 21 containers managed via Docker Compose.

## 📋 Overview

This stack includes **21 containers** for a complete media automation and monitoring solution:

### Media Services (8 containers)
- **Plex** - Media server with hardware transcoding
- **Sonarr** - TV show automation
- **Radarr** - Movie automation
- **Bazarr** - Subtitle automation
- **SABnzbd** - Usenet downloader
- **Overseerr** - Media request management
- **Tautulli** - Plex statistics and monitoring
- **NZBHydra2** - NZB meta search

### Media Management (3 containers)
- **Kometa** - Plex metadata and collection management
- **ErsatzTV** - Custom IPTV channels from your media
- **Huntarr** - Media discovery utility

### Infrastructure (7 containers)
- **Nginx Proxy Manager** - Reverse proxy with Let's Encrypt
- **Requestrr** - Discord bot for media requests
- **iCloudPD** - Automatic iCloud photo backup
- **Scrutiny** - Hard drive S.M.A.R.T. monitoring
- **Glances** - System resource monitoring
- **Dozzle** - Real-time Docker log viewer
- **Speedtracker** - Internet speed test tracking

### Backend Services (3 containers)
- **Checkmate** - Uptime monitoring backend
- **MongoDB** - Database for Checkmate
- **Redis** - Cache for Checkmate

## 🔒 Security Hardening

All services include security hardening based on Docker best practices:

- ✅ **Non-root users** - Services run as `nobody:nogroup` or PUID/PGID
- ✅ **TTY/stdin disabled** - Explicit `tty: false`, `stdin_open: false`
- ✅ **No new privileges** - `security_opt: - no-new-privileges:true`
- ✅ **Tmpfs configuration** - `/tmp` with `noexec,nosuid,nodev` flags
- ✅ **Resource limits** - Memory and CPU limits on all services
- ✅ **Logging limits** - Max 10MB log files with rotation
- ✅ **PID limits** - Prevents fork bomb attacks
- ✅ **Network isolation** - Custom networks for service separation

**Security Score: 8/10**

## 📦 Prerequisites

1. **Unraid** with Docker support enabled
2. **Docker Compose Manager** plugin installed (from Community Applications)
3. **Storage paths**:
   - `/mnt/user/appdata` - Application data
   - `/mnt/user/media` - Media library
   - `/mnt/cache/downloads` - Downloads directory
   - `/mnt/disk1/appdata` - Disk-specific appdata

## 🚀 Quick Start

### 1. Deploy via Unraid Docker Compose Manager

1. **Install Plugin** (if not already):
   - Go to Apps tab in Unraid
   - Search for "Docker Compose Manager"
   - Install it

2. **Navigate to Compose Manager**:
   - Docker tab → Compose Manager

3. **Create Stack**:
   - Name: `unraid_beszel_agent` (or your preferred name)
   - Description: "Complete Unraid media and monitoring stack"

4. **Copy Files**:
   ```bash
   # SSH to Unraid
   ssh root@<unraid-ip>

   # Navigate to compose manager directory
   cd /boot/config/plugins/compose.manager/projects/

   # Clone or copy this project folder
   git clone <repo> unraid_beszel_agent
   # OR manually copy docker-compose.yml and .env.example

   cd unraid_beszel_agent
   ```

5. **Configure Environment**:
   ```bash
   cp .env.example .env
   nano .env  # Fill in your values
   ```

6. **Deploy**:
   ```bash
   docker compose up -d
   ```

### 2. Required Environment Variables

Edit `.env` and configure:

**Essential:**
- `PUID=99` / `PGID=100` (Unraid defaults)
- `TZ=America/Chicago` (your timezone)
- `UNRAID_IP` (your Unraid server IP)
- `PLEX_CLAIM` (from https://www.plex.tv/claim/)
- `BESZEL_AGENT_KEY` (from Beszel hub)

**Optional** (set as needed):
- Kometa configuration
- iCloud credentials
- Dozzle credentials
- Speedtest settings
- Checkmate URLs

## 🌐 Service Access

After deployment, services are available at:

| Service | Port | URL |
|---------|------|-----|
| **Plex** | 32400 | http://unraid-ip:32400/web |
| **Sonarr** | 8989 | http://unraid-ip:8989 |
| **Radarr** | 7878 | http://unraid-ip:7878 |
| **Bazarr** | 6767 | http://unraid-ip:6767 |
| **SABnzbd** | 8080 | http://unraid-ip:8080 |
| **Overseerr** | 5055 | http://unraid-ip:5055 |
| **Tautulli** | 8181 | http://unraid-ip:8181 |
| **NZBHydra2** | 5076 | http://unraid-ip:5076 |
| **Nginx Proxy Manager** | 81 | http://unraid-ip:81 |
| **Requestrr** | 4545 | http://unraid-ip:4545 |
| **Scrutiny** | 8383 | http://unraid-ip:8383 |
| **Glances** | 61208 | http://unraid-ip:61208 |
| **Dozzle** | 8084 | http://unraid-ip:8084 |
| **Speedtracker** | 8765 | http://unraid-ip:8765 |
| **Huntarr** | 5702 | http://unraid-ip:5702 |
| **Checkmate** | 52343 | http://unraid-ip:52343 |

## 🔧 Maintenance

### Update All Containers

```bash
cd /boot/config/plugins/compose.manager/projects/unraid_beszel_agent
docker compose pull
docker compose up -d
docker image prune -f
```

### Update Specific Service

```bash
docker compose up -d --force-recreate --no-deps plex
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f plex

# Last 100 lines
docker compose logs --tail=100 sonarr
```

### Restart Service

```bash
docker compose restart plex
```

### Stop All

```bash
docker compose down
```

## 📊 Resource Usage

**Total Stack:**
- **Memory**: ~18GB maximum limit
- **Typical Usage**: 4-6GB active
- **CPU**: <5% idle, up to 100% during transcoding

## 🔍 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose logs <service-name>

# Check port conflicts
netstat -tulpn | grep <port>

# Verify configuration
docker compose config
```

### Permission Errors

```bash
# Fix permissions
chown -R 99:100 /mnt/user/appdata/<service>
chown -R 99:100 /mnt/disk1/appdata/<service>
chown -R 99:100 /mnt/user/media
```

### Plex Hardware Transcoding Not Working

```bash
# Verify Intel QuickSync is available
ls -la /dev/dri

# Should show /dev/dri/card0 and /dev/dri/renderD128
```

## 📝 Notes

### Unraid Paths
- `/mnt/user/` - User shares (spans all disks)
- `/mnt/cache/` - Cache-only (faster for downloads)
- `/mnt/disk1/` - Specific disk

### User/Group IDs
- `99` - Unraid 'nobody' user
- `100` - Unraid 'users' group

### Hardware Acceleration
- Plex and ErsatzTV support Intel QuickSync via `/dev/dri`
- Scrutiny runs privileged for disk access
- Glances uses host PID for monitoring

### Data Persistence
- All data in `/mnt/user/appdata/` and `/mnt/disk1/appdata/`
- Volumes are bind mounts (not Docker volumes)
- Destroying containers does NOT destroy data

## 🔗 Related Links

- [Docker Compose Manager Plugin](https://forums.unraid.net/topic/114415-plugin-docker-compose-manager/)
- [Unraid Docker Documentation](https://docs.unraid.net/unraid-os/manual/docker-management/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 📄 File Structure

```
unraid_beszel_agent/
├── docker-compose.yml    # All 21 services
├── .env.example         # Environment variable template
├── .env                 # Your configuration (not in git)
├── .gitignore          # Excludes .env
└── README.md           # This file
```

## 🆘 Support

Check logs and verify:
1. `.env` file has all required variables
2. Unraid paths exist with correct permissions (99:100)
3. No port conflicts with existing containers
4. Services can communicate on their networks

---

**Services**: 21 containers
**Security Score**: 8/10
**Generated**: 2026-01-10
