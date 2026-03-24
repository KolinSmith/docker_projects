# Borg (Unraid) Docker Stack

Unified Docker Compose stack for Borg (Unraid server) including monitoring and document management.

## Services

| Service | Description | Port |
|---------|-------------|------|
| **Monitoring** | | |
| `beszel-agent` | System and Docker monitoring agent | 45876 |
| **Document Management** | | |
| `paperless-ngx` | Document management with OCR | 8000 |
| `paperless-postgres` | PostgreSQL database | - |
| `paperless-redis` | Redis cache/queue | - |
| `paperless-gotenberg` | Document conversion | - |
| `paperless-tika` | Text extraction | - |
| **AI Services (GPU-accelerated)** | | |
| `paperless-ollama` | Local LLM inference | 11434 |
| `paperless-open-webui` | Ollama model management | 3001 |
| `paperless-ai` | Auto metadata suggestions | 3000 |
| `paperless-gpt` | Vision OCR enhancement | 3002 |
| `paperless-webdav` | WebDAV endpoint for Scanner Pro uploads | 8008 |
| **Utilities** | | |
| `dozzle` | Container log viewer | 8484 |

## Hardware

**NVIDIA GPU:** GPU-a0c637a6-a078-71e5-ffba-72dd70ee8933
- Used for Ollama LLM inference and vision models
- Enables fast OCR and metadata generation

---

# Beszel Agent

Monitor your Unraid server with Beszel - resource monitoring and Docker container tracking.

## Overview

The Beszel agent monitors:
- CPU, RAM, disk usage
- Network statistics
- All Docker containers running on Unraid
- System temperatures and sensors

## Unraid Docker Compose Manager Setup

### Important Path Information

**Docker Compose Manager stores stacks in:**
```
/boot/config/plugins/compose.manager/projects/
```

**This stack should be deployed to:**
```
/boot/config/plugins/compose.manager/projects/beszel-agent/
```

### Deployment Steps

#### 1. Access Docker Compose Manager

1. Open Unraid web UI
2. Navigate to: **Docker** → **Compose Manager** (or **Plugins** → **Docker Compose Manager**)

#### 2. Create New Stack

1. Click **"Add New Stack"** or **"Create Stack"**
2. **Stack Name:** `beszel-agent`
3. **Description:** "Beszel monitoring agent for Unraid"

#### 3. Add Files to Stack

**Method A: Via Web UI**
- Paste `docker-compose.yml` content into the editor
- Create `.env` file from `.env.example`

**Method B: Via SSH/Terminal**
```bash
# SSH to Unraid
ssh root@<unraid-ip>

# Navigate to compose manager projects directory
cd /boot/config/plugins/compose.manager/projects/

# Create stack directory
mkdir -p beszel-agent
cd beszel-agent

# Copy files from this repo
# (Either git clone or manually copy docker-compose.yml and .env.example)

# Create .env from example
cp .env.example .env
nano .env  # Add your BESZEL_AGENT_KEY
```

#### 4. Get SSH Key from Beszel Hub

1. **Access Beszel Hub** (on Voyager or wherever hub is running):
   ```
   http://192.168.9.2:8090
   ```

2. **Add New System:**
   - Click "Systems" → "Add System"
   - **Name:** `Unraid`
   - **Host:** `<unraid-ip>` (or Unraid's Tailscale IP if using Tailscale)
   - **Port:** `45876`

3. **Copy SSH Public Key:**
   - Beszel will generate an SSH public key
   - Copy the entire key (starts with `ssh-ed25519`)

4. **Add to `.env` file:**
   ```bash
   BESZEL_AGENT_KEY=ssh-ed25519_AAAAC3NzaC1lZDI1NTE5AAAA...
   ```

#### 5. Deploy Stack

**Via Web UI:**
1. Click **"Compose Up"** or **"Start"**
2. Monitor logs in the UI

**Via SSH:**
```bash
cd /boot/config/plugins/compose.manager/projects/beszel-agent
docker compose up -d
```

#### 6. Verify Connection

1. **Check container status:**
   ```bash
   docker ps | grep beszel-agent
   ```

2. **Check logs:**
   ```bash
   docker logs beszel-agent
   ```

3. **Verify in Beszel Hub:**
   - Go to Beszel web UI
   - Check "Systems" page
   - **Unraid** should show as "Connected" (green status)

## Configuration

### Network

- **Mode:** `host` (simplest for Unraid)
- **Port:** 45876 (agent listens, hub connects)
- **No port forwarding needed** if hub and agent are on same network

### Volumes

| Volume | Purpose |
|--------|---------|
| `./beszel_agent_data` | Agent configuration and data |
| `/var/run/docker.sock:ro` | Monitor Docker containers (read-only) |
| `/:/host:ro` | Monitor system resources (read-only) |

### Security

- ✅ `no-new-privileges:true` - Prevents privilege escalation
- ✅ `cap_drop: ALL` - Drops all capabilities
- ✅ Selective `cap_add` - Only adds necessary capabilities
- ✅ Read-only mounts - Docker socket and host filesystem are read-only

### Resource Limits

Default limits (adjust as needed):
- **Memory limit:** 128MB
- **Memory reservation:** 64MB

Beszel agent is very lightweight and typically uses <50MB RAM.

## Monitoring

### What Gets Monitored

**System Resources:**
- CPU usage (per core and total)
- RAM usage (used/available)
- Disk usage (array, cache, pools)
- Network I/O (bytes in/out)

**Docker Containers:**
- All containers on Unraid
- Container CPU and memory usage
- Container status (running/stopped)

**Optional (if sensors available):**
- CPU temperature
- Disk temperatures
- Fan speeds

## Troubleshooting

### Agent Not Connecting

**Check container status:**
```bash
docker ps | grep beszel
docker logs -f beszel-agent
```

**Verify port accessibility:**
```bash
# From Unraid
ss -tlnp | grep 45876

# From Beszel hub (Voyager)
nc -zv borg 45876
```

**Check firewall:**
- Unraid doesn't typically have a firewall enabled
- If using pfSense, ensure port 45876 is open between VLANs

### SSH Key Issues

**If hub can't connect:**
1. Regenerate system in Beszel hub
2. Get new SSH key
3. Update `.env` file with new key
4. Restart container:
   ```bash
   docker compose restart beszel-agent
   ```

### Permission Errors

**If agent can't read Docker socket:**
```bash
# Check Docker socket permissions
ls -la /var/run/docker.sock

# Verify agent has necessary capabilities
docker inspect beszel-agent | grep -A 20 CapAdd
```

## Updating

### Via Docker Compose Manager UI
1. Navigate to stack in web UI
2. Click **"Compose Pull"** (pulls latest image)
3. Click **"Compose Up"** (recreates container)

### Via SSH
```bash
cd /boot/config/plugins/compose.manager/projects/beszel-agent
docker compose pull
docker compose up -d
```

## Uninstalling

### Via UI
1. Go to Docker Compose Manager
2. Select `beszel-agent` stack
3. Click **"Compose Down"**
4. Optionally delete the stack

### Via SSH
```bash
cd /boot/config/plugins/compose.manager/projects/beszel-agent
docker compose down
# Optionally remove data
rm -rf beszel_agent_data
```

## Integration with Beszel Hub

**Beszel Hub Location:**
- Running on Voyager (192.168.9.2)
- Web UI: http://192.168.9.2:8090

**Connection Methods:**

**Option 1: Direct IP (Recommended)**
- Hub connects to: `<unraid-ip>:45876`
- Fastest, simplest
- Works if on same network/VLAN

**Option 2: Tailscale (More Secure)**
- If Unraid has Tailscale installed
- Hub connects to: `<unraid-tailscale-ip>:45876`
- Works from anywhere
- More secure (encrypted WireGuard tunnel)

## File Structure

```
/boot/config/plugins/compose.manager/projects/beszel-agent/
├── docker-compose.yml       # Container configuration
├── .env                     # SSH key (not committed to git)
├── .env.example             # Template for .env
├── beszel_agent_data/       # Agent data (created at runtime)
└── README.md                # This file
```

## Notes

- **Persistent across reboots:** Yes (stored on /boot)
- **Auto-start:** Yes (restart: unless-stopped)
- **Resource impact:** Minimal (<50MB RAM, <1% CPU)
- **Network traffic:** Very low (only metrics, no continuous streaming)

## Related Services

- **Beszel Hub:** Running on Voyager (192.168.9.2:8090)
- **Other monitored systems:** DMZ, DS9, Defiant, Operator (future)

## Resources

- [Beszel Documentation](https://github.com/henrygd/beszel)
- [Docker Compose Manager Plugin](https://forums.unraid.net/topic/114415-plugin-docker-compose-manager/)
- [Unraid Docker Documentation](https://docs.unraid.net/unraid-os/manual/docker-management/)

---

# Paperless-ngx Document Management

AI-powered document management with OCR, tagging, and full-text search.

## Quick Start

### 1. Pre-create directories
```bash
mkdir -p /mnt/disks/appdataAndDocker/appdata/paperless-ngx/{data,postgres,redis,ollama,open-webui,paperless-ai,paperless-gpt/prompts}
# media/export/consume already exist from previous install at /mnt/user/paperless/
```

### 2. Configure environment
```bash
cd /boot/config/plugins/compose.manager/projects/borg
cp .env.example .env
nano .env
```

Set these required variables:
- `PAPERLESS_DBPASS` - Secure database password
- `PAPERLESS_SECRET_KEY` - Generate with: `openssl rand -base64 32`
- `PAPERLESS_API_TOKEN` - Generate after first login (Profile → API Tokens)

### 3. Deploy

> **Note:** The paperless stack lives directly at the root of the compose manager projects directory, not in a subdirectory:
> ```
> /boot/config/plugins/compose.manager/projects/docker-compose.yml
> ```
> Deploy with:
```bash
sudo docker compose -f /boot/config/plugins/compose.manager/projects/docker-compose.yml up -d
```

### 4. Access Paperless
- URL: http://borg:8000
- Create admin account on first visit
- Generate API token: Profile → API Tokens (paste into `.env`)

### 5. Pull AI models (via Open WebUI)
- Access: http://borg:3001
- Pull models: `llama3.2:3b` and `qwen2.5vl:7b`

## Features

**Core:**
- OCR with multiple language support
- Full-text search across all documents
- Automatic tagging and organization
- Email import support

**AI-Enhanced (GPU-accelerated):**
- Automatic metadata suggestions (Paperless-AI)
- Auto-tagging and title generation (Paperless-GPT via `llama3.2:3b`)
- Vision OCR (Paperless-GPT via `qwen2.5vl:7b`)
- Local LLM inference (Ollama with NVIDIA GPU)

> **Note on Vision OCR performance:** `qwen2.5vl:7b` works correctly but is slow (~6 min/doc) because the 7B
> model exceeds the GTX 1660's 6GB VRAM — Ollama offloads ~9 layers to CPU RAM. `minicpm-v:8b` crashes on the
> GTX 1660 with `GGML_ASSERT(buffer) failed` on page 2+ of multi-page docs (Turing architecture limitation).
> After upgrading to an Ampere GPU (16GB+ VRAM), switch `VISION_LLM_MODEL` back to `minicpm-v:8b` for full
> GPU-accelerated speed. See `.claude/plans/2026-03-22-gpu-upgrade.md`.

## Usage

**Drop documents to consume:**
```bash
cp /path/to/document.pdf /mnt/user/Documents/consume/
```

Paperless automatically:
1. Imports the document
2. Performs OCR
3. Generates metadata (if AI enabled)
4. Makes it searchable

## GPU Configuration

Ollama uses NVIDIA GPU: `GPU-a0c637a6-a078-71e5-ffba-72dd70ee8933`

To verify GPU is being used:
```bash
docker exec paperless-ollama nvidia-smi
```

## Scanner Pro Upload (iPhone → Paperless)

Documents can be scanned and uploaded directly from iPhone using [Scanner Pro](https://readdle.com/scannerpro) via WebDAV.

### How it works

The `paperless-webdav` container (bytemark/webdav) exposes the Paperless consume directory as a WebDAV endpoint. Scanner Pro uploads scans to WebDAV, which drops them into `/mnt/user/paperless/consume`, where Paperless auto-ingests them.

### External access setup

The WebDAV endpoint is exposed externally via a `scan` subdomain routed through Cloudflare and Nginx Proxy Manager:

1. **Cloudflare DNS** — Add a CNAME record:
   - Name: `scan`
   - Target: your home/server IP (or use Cloudflare proxy)

2. **Nginx Proxy Manager** — Add a proxy host:
   - Domain: `scan.yourdomain.com`
   - Forward to: `192.168.9.7:8008` (internal Borg IP)
   - SSL: Let's Encrypt cert, Force SSL enabled

3. **Scanner Pro config** (iOS):
   - Go to: Settings → Cloud Services → Add → WebDAV
   - Server: `https://scan.yourdomain.com`
   - Path: `/`
   - Username/Password: set in `webdav/.env` (copy from `webdav/.env.example`)

### Flow

```
Scanner Pro → HTTPS → Cloudflare → NPM → paperless-webdav:8008
                                              ↓
                              /mnt/user/paperless/consume
                                              ↓
                              Paperless auto-ingests → OCR → AI tagging
```

The `AI Auto-Process` workflow in Paperless fires on every new document, automatically applying the `paperless-gpt-auto` and `paperless-gpt-ocr-auto` tags to trigger AI processing.

---

## Troubleshooting

**AI services not working:**
1. Ensure API token is set in `.env`
2. Verify models are pulled in Open WebUI
3. Check Ollama logs: `docker logs paperless-ollama`

**OCR not working:**
1. Check Tika/Gotenberg logs
2. Verify PAPERLESS_TIKA_ENABLED=1

**WebDAV upload not appearing in Paperless:**
1. Verify file landed in consume dir: `ls /mnt/user/paperless/consume/`
2. Check paperless-webdav logs: `docker logs paperless-webdav`
3. Check paperless-ngx consumer logs: `docker logs paperless-ngx | grep consumer`

## References

- [Paperless-ngx Documentation](https://docs.paperless-ngx.com/)
- [TechnoTim's Guide](https://technotim.com/posts/paperless-ngx-local-ai/)
- [timothystewart6/paperless-stack](https://github.com/timothystewart6/paperless-stack)
