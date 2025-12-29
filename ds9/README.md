# Pi-hole DS9

DNS server with ad-blocking for homelab network.

## Quick Start

### 1. Create .env file from example

```bash
cp .env.example .env
```

### 2. Set Pi-hole password

The password should come from Ansible vault variable `vault_pihole_webpassword`.

If setting manually, generate hashed password:
```bash
echo -n 'your_password' | sha256sum | awk '{print $1}'
```

Add to `.env`:
```
PIHOLE_WEBPASSWORD=your_hashed_password_here
```

### 3. Deploy Pi-hole

```bash
docker-compose up -d
```

### 4. Configure custom DNS entries (Optional)

After first startup, copy the custom DNS configuration:
```bash
cp custom-dns-overrides.conf.example etc-dnsmasq.d/03-dns-overrides.conf
```

Edit the file to match your homelab IPs, then restart:
```bash
docker-compose restart
```

### 5. Access Web Interface

```
http://<server-ip>/admin
```

Login with the password from your .env file (unhashed version).

## Configuration

### Whitelist Domains

From Pi-hole web UI:
- Settings → Whitelist
- Add: dartsearch.net, googleadservices.com, clickserve.dartsearch.net, ad.doubleclick.net, ally.com, protonmail.com, loftliving.com, claude.ai

Or via CLI:
```bash
docker exec pihole-ds9 pihole -w dartsearch.net googleadservices.com clickserve.dartsearch.net ad.doubleclick.net ally.com protonmail.com loftliving.com claude.ai
```

### Blacklist Domains

From Pi-hole web UI:
- Settings → Blacklist
- Add: app-analytics-v2.snapchat.com, metrics.icloud.com, metrics.plex.tv, analytics.plex.tv

Or via CLI:
```bash
docker exec pihole-ds9 pihole -b app-analytics-v2.snapchat.com metrics.icloud.com metrics.plex.tv analytics.plex.tv
```

## Gravity-Sync

To sync block lists between DS9 and Defiant, gravity-sync can be configured separately.

## Ansible Deployment

This configuration matches the `deploy_pihole` Ansible role settings.

Secrets are managed in Ansible vault:
- `vault_pihole_webpassword` - Web interface password (hashed)

## Networking

- **DNS (TCP/UDP):** Port 53
- **Web Interface (HTTP):** Port 80
- **Web Interface (HTTPS):** Port 443 (optional, commented out by default)

## Volumes

- `./etc-pihole` - Pi-hole configuration and gravity database
- `./etc-dnsmasq.d` - DNSMasq configuration (custom DNS entries)

## Monitoring

Add to Uptime Kuma:
- **Type:** DNS
- **Hostname:** ds9.internal.homelab.gg
- **Port:** 53
- **Record Type:** A
- **Query:** google.com

## Logs

```bash
# Follow logs
docker logs -f pihole-ds9

# Check query log
docker exec pihole-ds9 pihole -t
```

## Troubleshooting

### DNS not resolving

Check container is running:
```bash
docker ps | grep pihole-ds9
```

Check DNS is responding:
```bash
dig @<server-ip> google.com
```

### Can't access web interface

Check port 80 is not in use:
```bash
sudo netstat -tulpn | grep :80
```

### Reset password

```bash
docker exec -it pihole-ds9 pihole -a -p
```

## Server Information

- **Hostname:** ds9
- **Server IP:** 192.168.9.3 (expected)
- **Upstream DNS:** 192.168.3.1 (pfSense)
- **Paired with:** Defiant (192.168.9.4) for redundancy
