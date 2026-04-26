# Borg Stack — Unraid Media & Utility Stack

Full Docker Compose stack for the Borg Unraid server. Covers media management, monitoring, reverse proxy, and utility services. Managed via the [Unraid Docker Compose Manager](https://forums.unraid.net/topic/114415-plugin-docker-compose-manager/) plugin.

---

## Services

### Media

| Container | Image | Port | Description |
|-----------|-------|------|-------------|
| `plex` | plexinc/pms-docker:plexpass | 32400 (host) | Media server. PlexPass with hardware transcoding via Intel QuickSync. |
| `sabnzbd` | linuxserver/sabnzbd | 8080, 9090 | Usenet downloader. |
| `sonarr` | linuxserver/sonarr | 8989 | TV show automation. |
| `radarr` | linuxserver/radarr | 7878 | Movie automation. |
| `bazarr` | linuxserver/bazarr | 6767 | Subtitle automation for Sonarr/Radarr. |
| `overseerr` | linuxserver/overseerr | 5055 | Media request management. |
| `requestrr` | thomst08/requestrr | 4545 | Discord bot for media requests (integrates with Overseerr). |
| `nzbhydra2` | linuxserver/nzbhydra2 | 5076 | Usenet indexer aggregator. |
| `tautulli` | linuxserver/tautulli | 8181 | Plex statistics and monitoring. |
| `kometa` | kometateam/kometa | — | Plex metadata manager (collections, overlays, ratings). Runs on schedule. |
| `ersatztv` | jasongdove/ersatztv | 8409 (host) | Virtual TV channel server for live TV simulation in Plex. |
| `huntarr` | hotdari/huntarr | 5702 | Missing media hunter for Sonarr/Radarr. |

### Infrastructure

| Container | Image | Port | Description |
|-----------|-------|------|-------------|
| `nginxproxymanager` | jc21/nginx-proxy-manager | 80, 443, 81 | Reverse proxy with Let's Encrypt SSL. Admin UI on port 81. |
| `icloudpd` | boredazfcuk/icloudpd | — | iCloud Photos downloader/sync. |

### Monitoring & System

| Container | Image | Port | Description |
|-----------|-------|------|-------------|
| `beszel-agent` | henrygd/beszel-agent | 45876 (host) | System metrics agent for Beszel monitoring hub. |
| `dockhand` | fnsys/dockhand | 3004 | Docker management UI. Manages containers on Borg and remote hosts (Voyager via Hawser edge agent). |
| `scrutiny` | analogj/scrutiny:master-omnibus | 8383 | Disk S.M.A.R.T. monitoring. |
| `glances` | nicolargo/glances | 61208 (host) | Real-time system resource monitoring. |
| `dozzle` | amir20/dozzle | 8084 | Docker container log viewer. |
| `speedtracker` | linuxserver/speedtest-tracker | 8765 | Scheduled internet speed tests with history. |
| `checkmate` | binarynate-llc/checkmate | 52343 | Uptime and service status monitoring. |
| `mongodb_checkmate` | mongo | 27017 | MongoDB database for Checkmate. |
| `redis_checkmate` | redis | 6379 | Redis cache for Checkmate. |

---

## Setup

### 1. Prerequisites

- Unraid with [Docker Compose Manager plugin](https://forums.unraid.net/topic/114415-plugin-docker-compose-manager/) installed
- Compose file deployed at: `/boot/config/plugins/compose.manager/projects/docker-compose.yml`

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your values. See the comments in `.env.example` for guidance on each variable.

**Required to change before first run:**
- `UNRAID_IP` — your Unraid server's IP
- `PLEX_CLAIM` — get from https://www.plex.tv/claim (expires in 4 minutes)
- `BESZEL_AGENT_KEY` — SSH public key from your Beszel hub
- `ICLOUD_APPLE_ID` — your Apple ID email
- `DOZZLE_PASSWORD` — set a real password
- `DOZZLE_KEY` — random secret string
- `SPEEDTEST_APP_KEY` — generate with `openssl rand -base64 32`, prefix with `base64:`
- `CHECKMATE_JWT_SECRET` — random secret string

### 3. Deploy

**Deploy all services:**
```bash
sudo docker compose -f /boot/config/plugins/compose.manager/projects/docker-compose.yml up -d
```

**Deploy a single service:**
```bash
sudo docker compose -f /boot/config/plugins/compose.manager/projects/docker-compose.yml up -d plex
```

**View logs:**
```bash
sudo docker logs -f plex
```

---

## Directory Structure

Appdata is stored on disk to survive Unraid array restarts. The paths in this compose file follow the Unraid convention:

```
/mnt/user/appdata/     → Unraid user share (array + cache)
/mnt/disk1/appdata/    → Pinned to disk1 (faster single-disk access for config)
/mnt/cache/downloads/  → Cache drive (fast write for downloads)
/mnt/user/media/       → Media share (movies, TV, music, photos)
```

---

## Network Layout

| Network | Services | Purpose |
|---------|----------|---------|
| `host` | beszel-agent, plex, ersatztv, glances | Direct host networking for performance or multicast |
| `bridge` | Most services | Standard isolated bridge with port mapping |
| `proxy` | nginxproxymanager, overseerr | Shared network for reverse proxy |
| `checkmate` (internal) | checkmate, mongodb_checkmate, redis_checkmate | Isolated internal network |

---

## Service Notes

### Plex

- Uses `plexpass` tag — requires a Plex Pass subscription
- Hardware transcoding via Intel QuickSync (`/dev/dri`)
- NVIDIA GPU transcoding (NVENC) is configured separately via Unraid's GPU passthrough — not reflected in this compose file
- `PLEX_CLAIM` is only used on first run to link the server to your Plex account

### ErsatzTV

- Uses `network_mode: host` — accessible at `borg:8409`
- Has access to `/dev/dri` for hardware transcoding
- May need `--runtime=nvidia` added to `extra_params` in Unraid if NVIDIA GPU transcoding is desired

### iCloudpd

- Requires interactive login on first run to authenticate with Apple 2FA
- After first run, authentication is stored in `/mnt/disk1/appdata/icloudpd/config`
- `ICLOUD_SYNC_INTERVAL` defaults to 86400 (24 hours)

### Kometa

- Runs on schedule defined by `KOMETA_TIME` (default: 3:00 AM)
- Set `KOMETA_RUN=true` to trigger an immediate run on container start
- Config lives at `/mnt/disk1/kometa/config.yml` — see [Kometa docs](https://kometa.wiki)

### Scrutiny

- Requires `privileged: true` for raw disk access
- Device list (`/dev/sda` through `/dev/nvme0n1`) must match your actual drives
- Update the `devices` list if your drive layout changes

### Checkmate

- Backend API: port `52343`
- Frontend (separate container, not in this compose): typically port `3001`
- MongoDB and Redis run on the internal `checkmate` network — not accessible outside the stack

### Nginx Proxy Manager

- Admin UI: `http://borg:81` — default login is `admin@example.com` / `changeme`
- Change admin password immediately on first login
- Paired with Cloudflare DNS for external subdomain exposure

---

## Known Gaps / Not Yet Included

The following containers run on Borg but are not yet in this compose file:

- **Immich** — photo/video backup (self-hosted Google Photos alternative)
- **Nextcloud** — file sync and collaboration
- **Gitea** — self-hosted Git server
- **MariaDB** — shared database for other services
- **Lancache** — game download caching (Steam, Epic, etc.)
- **Lancache-DNS** — DNS for Lancache

These will be added in future PRs as they are formalized.

---

## Related

- Paperless-ngx AI stack: [`../paperless/`](../paperless/README.md)
- GPU upgrade plan: [`.claude/plans/2026-03-22-gpu-upgrade.md`](../../.claude/plans/2026-03-22-gpu-upgrade.md)
