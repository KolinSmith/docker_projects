# Forgejo Actions Runner - Orange Pi R1 Plus

This directory contains the Docker Compose configuration for a dedicated Forgejo Actions runner.

## Overview

**Purpose:** CI/CD automation runner for Forgejo instance

**Hardware:** Orange Pi R1 Plus
- CPU: RK3328 (Quad-core ARM Cortex-A53 @ 1.5GHz)
- RAM: 1GB
- Architecture: ARM64 (aarch64)

## Runner Capabilities

**Labels:** `arm64`, `docker`, `linux`, `ansible`

**Use Cases:**
- Ansible playbook syntax checking and linting
- Docker image builds (ARM64 architecture)
- Automated deployments via Ansible
- Infrastructure tests
- Repository maintenance tasks

## Deployment

### Prerequisites

1. **Forgejo Registration Token**
   - Access your Forgejo web UI
   - Navigate to: Site Administration → Actions → Runners
   - Click "Create new Runner"
   - Copy the registration token

2. **Ansible Vault Variable**
   - Add to `group_vars/all/vault.yml`:
     ```yaml
     vault_forgejo_runner_token: "your_registration_token_here"
     ```
   - Add to `group_vars/all/docker_vars.yml`:
     ```yaml
     docker_forgejo_runner_token: "{{ vault_forgejo_runner_token }}"
     ```

3. **Ansible Inventory**
   - Add to inventory (e.g., `inventory/servers.yml`):
     ```yaml
     [forgejo_runner]
     forgejo-runner ansible_host=192.168.9.X ansible_user=dax
     ```

### Deploy via Ansible

```bash
# Deploy to Orange Pi R1 Plus
cd ~/code_base/ansible_projects
ansible-playbook playbooks/server_provision_script/server_provision_script.yml -l forgejo-runner

# Or just deploy Docker services
ansible-playbook playbooks/deploy_docker/deploy_docker.yml -l forgejo-runner
```

### Manual Deployment (if needed)

```bash
# SSH to Orange Pi
ssh dax@192.168.9.X

# Navigate to deployment directory
cd ~/docker

# Start runner
docker compose up -d

# Check logs
docker compose logs -f forgejo-runner
```

## Verification

### 1. Check Runner Registration

**In Forgejo Web UI:**
- Navigate to: Site Administration → Actions → Runners
- Should see: `orange-pi-r1-plus` with status "Idle" (green)

### 2. Check Container Status

```bash
# On Orange Pi
docker compose ps
docker compose logs -f forgejo-runner
```

### 3. Test with a Workflow

Create `.forgejo/workflows/test.yml` in a test repository:

```yaml
name: Test ARM64 Runner

on:
  push:
    branches: [ main ]

jobs:
  test-arm64:
    runs-on: arm64
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: System info
        run: |
          uname -a
          echo "CPU info:"
          cat /proc/cpuinfo | grep "model name" | head -1
          echo "Memory:"
          free -h
          echo "Disk:"
          df -h

      - name: Test Docker
        run: |
          docker --version
          docker run --rm hello-world

      - name: Success
        run: echo "ARM64 runner is working!"
```

## Example Workflows

### Ansible Playbook Linting

```yaml
name: Ansible Lint

on: [push, pull_request]

jobs:
  ansible-lint:
    runs-on: arm64
    steps:
      - uses: actions/checkout@v3
      - name: Install Ansible
        run: |
          sudo apt update
          sudo apt install -y ansible ansible-lint
      - name: Run ansible-lint
        run: ansible-lint playbooks/
```

### Docker Image Build (ARM64)

```yaml
name: Build ARM Docker Image

on:
  push:
    branches: [ main ]

jobs:
  build-arm:
    runs-on: arm64
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker image
        run: docker build -t myapp:arm64 .
      - name: Test image
        run: docker run --rm myapp:arm64 --version
```

## Monitoring

### Container Health

```bash
# Check container status
docker compose ps

# View logs
docker compose logs -f forgejo-runner

# Check resource usage
docker stats forgejo-runner
```

### Add to Monitoring Stack

1. **Uptime Kuma**
   - Add Docker container health check
   - Monitor runner availability

2. **Beszel Agent**
   - Deploy Beszel agent to Orange Pi
   - Monitor CPU, RAM, disk usage
   - Set up alerts for resource thresholds

## Maintenance

### Update Runner

```bash
# Pull latest image
docker compose pull

# Recreate container
docker compose up -d

# Remove old images
docker image prune -f
```

### View Runner Activity

Check in Forgejo Web UI:
- Site Administration → Actions → Runners
- View jobs executed, last seen, status

## Troubleshooting

### Runner Not Appearing in Forgejo

**Check:**
```bash
# Verify container is running
docker compose ps

# Check logs for errors
docker compose logs forgejo-runner

# Verify network connectivity to Forgejo instance
curl -I $FORGEJO_INSTANCE_URL
```

### Jobs Not Running

**Verify:**
- Runner labels match job requirements in workflow
- Runner has "Idle" status in Forgejo UI
- Sufficient resources (RAM, disk space) available
- Docker socket is accessible: `docker ps`

### Permission Denied on Docker Socket

**Fix:**
```bash
# Ensure user is in docker group
sudo usermod -aG docker dax
newgrp docker

# Verify
docker ps  # Should work without sudo
```

## Security Notes

1. **User Permissions**
   - Runner runs as user 1000:1000 (not root)
   - Has Docker socket access (required for container jobs)
   - Limited capabilities via `cap_drop: ALL` + specific `cap_add`

2. **Token Security**
   - Registration token stored in Ansible vault
   - Never commit .env files to git
   - Rotate tokens periodically

3. **Workflow Security**
   - Review workflows before allowing execution
   - Use secrets management for sensitive data
   - Limit workflow permissions where possible

## Resources

- [Forgejo Actions Documentation](https://forgejo.org/docs/latest/user/actions/)
- [Forgejo Runner Documentation](https://code.forgejo.org/forgejo/runner)
- [GitHub Actions Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions) (compatible)

## Configuration Details

**Service:** forgejo-runner
**Image:** code.forgejo.org/forgejo/runner:latest
**Container Name:** forgejo-runner
**Network:** Custom bridge network (`runner_network`)
**Volumes:**
- `runner_data` - Runner persistent data
- `runner_config` - Runner configuration
- `/var/run/docker.sock` - Docker socket (for running containers)

**Resource Limits:**
- Memory: 512MB limit / 256MB reservation
- PIDs: 256 max processes
- Tmpfs: 512MB with noexec,nosuid,nodev

**Labels:**
- `arm64` - ARM64 architecture builds
- `docker` - Can run Docker containers
- `linux` - Linux-based jobs
- `ansible` - Can run Ansible playbooks
