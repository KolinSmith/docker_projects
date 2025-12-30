# Beszel Agent for Unraid

Monitor your Unraid server with Beszel - resource monitoring and Docker container tracking.

## Overview

This stack deploys the Beszel agent on Unraid to monitor:
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
docker-compose up -d
```

#### 6. Verify Connection

1. **Check container status:**
   ```bash
   docker ps | grep beszel-agent-unraid
   ```

2. **Check logs:**
   ```bash
   docker logs beszel-agent-unraid
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
docker logs beszel-agent-unraid
```

**Verify port accessibility:**
```bash
# From Unraid
ss -tlnp | grep 45876

# From Beszel hub (Voyager)
nc -zv <unraid-ip> 45876
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
   docker-compose restart beszel-agent
   ```

### Permission Errors

**If agent can't read Docker socket:**
```bash
# Check Docker socket permissions
ls -la /var/run/docker.sock

# Verify agent has necessary capabilities
docker inspect beszel-agent-unraid | grep -A 20 CapAdd
```

## Updating

### Via Docker Compose Manager UI
1. Navigate to stack in web UI
2. Click **"Compose Pull"** (pulls latest image)
3. Click **"Compose Up"** (recreates container)

### Via SSH
```bash
cd /boot/config/plugins/compose.manager/projects/beszel-agent
docker-compose pull
docker-compose up -d
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
docker-compose down
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
