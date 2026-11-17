# Borg Monitoring Stack

Prometheus + Grafana + exporters for Borg, plus the Beszel agent (migrated from
`borg-stack` 2026-10-05 -- same key, same hub registration, just managed from this
compose file now instead).

## Deploy

1. Copy `.env.example` to `.env` and fill in real values.
2. `docker compose up -d`
3. Grafana: `http://<borg-ip>:3003`. Prometheus: `http://<borg-ip>:9090`.

See `.claude/specs/2026-10-05-borg-monitoring-stack-design.md` (dotfiles repo)
for the full design and rationale.

## Status

Deployed and verified 2026-10-06. All 7 services (`beszel-agent`, `beszel-socket-proxy`,
`cadvisor`, `nvidia-gpu-exporter`, `snmp-exporter`, `prometheus`, `grafana`) running under
the `monitoring_stack` compose project. Prometheus `/targets` shows all 4 scrape targets
(`apc-ups`, `cadvisor`, `node-exporter`, `nvidia-gpu-exporter`) `UP`. Beszel hub on
Voyager confirmed actively reporting Borg (live SSH session, not just "container up").

Dashboards actually imported into Grafana (confirmed by checking each panel's underlying
query against live Prometheus data, not just "import succeeded"):

- **Node Exporter Full** -- dashboard ID `1860`
- **Nvidia GPU Metrics** -- dashboard ID `14574` (picked after grepping several
  candidates for real `nvidia_smi_*` metric coverage)
- **cAdvisor** -- dashboard ID `14282` (ID `893` was tried first, found to query
  pre-rename metric names this stack's exporters don't expose, deleted and replaced)
- **APC UPS** -- no public dashboard matched this stack's custom PowerNet-MIB metric
  names (`upsAdvOutputActivePower`, `upsAdvOutputLoad`, `upsBasicBatteryStatus`), so this
  one is hand-built (4 panels: output power, output load, battery status, output power
  time series), not imported from a public ID.

The APC UPS is reachable at **192.168.9.51** on the internal server VLAN (the
`snmp-exporter` target address -- not the SNMP community string, which is a separate,
still-default value; see "Known hardening TODO" below).

Smoke-tested values at deploy time: GPU power draw ~14-16W idle (plausible for an idle
GTX 1660), UPS output ~240-260W / ~24-26% load with battery status `2` (normal) --
plausible whole-rack draw on the SMT1500RM2U. The one smoke test not completed: confirming
the GPU power panel visibly climbs under active Ollama load. Borg's `paperless-ollama`
container was stopped at verification time, and starting/stopping it is a shared resource
outside this stack's scope -- left as an open item for Kolin to exercise himself (run an
Ollama completion and watch the GPU Metrics dashboard) or explicitly authorize in a future
session.

## Known hardening TODO

`snmp.yml`'s `apc_ups` module auths with community string `public` against the APC
AP9630 card (192.168.9.51) -- that's the card's unconfigured factory default, not a
secret anyone set. Fine for now since the card is only reachable on the internal
192.168.9.x server VLAN, but set a real read-only community string on the card and
update `snmp.yml` (and `.env.example`'s `UPS_SNMP_COMMUNITY`, kept there for
documentation even though it isn't substituted in automatically) when hardening this.

The `prometheus` service runs as `user: "0:0"` with `cap_add: [DAC_OVERRIDE]` --
every other container in this stack runs unprivileged (or, for `cadvisor`, with a
documented `privileged: true` exception). This one's root/capability combo is also a
deviation from that pattern, forced by where this project's live files happen to be
deployed: `/boot` (Unraid's flash share) is FAT-formatted with fixed, non-chmod-able
permissions (confirmed 700/600 root:root all the way down the path, even after an
explicit `chmod`), so the image's default `nobody` user can't read the bind-mounted
`prometheus.yml` there. `DAC_OVERRIDE` is only needed as a second-order consequence of
switching to root for that (the actual TSDB data volume is a normal Docker-managed
volume the stock `nobody` user already owns and could read/write with zero extra
capabilities on its own).

Tried Compose's non-Swarm `configs:` top-level construct as a way to inject just this
one file at a controlled uid/mode without needing root at all -- on this host's
classic (non-Swarm) Docker Engine, Compose silently implements `configs:` as an
ordinary bind mount and ignores `mode`/`uid`/`gid` entirely (confirmed by inspecting
the resulting container's mounts), so it hits the exact same FAT permission wall and
doesn't help. Revisit if/when: (a) this project's live files move off `/boot` to a
normal filesystem, or (b) Swarm mode (where `configs:` is a real first-class object,
not a bind mount) becomes an option.

`grafana` hits the identical FAT-on-`/boot` wall and carries the same `user: "0:0"` +
`cap_add: [DAC_OVERRIDE]` deviation, for the same reason: `grafana_datasources.yml` is
bind-mounted from this project's live directory (confirmed 700/600 root:root, same as
`prometheus.yml`), and the image's default non-root `grafana` user (472:472) can't read
it. Checked whether Grafana's default user already had access before adding this --
it didn't (the directory listing itself was `Permission denied` as the non-root
deploy user, let alone inside the container). Everything else about Grafana's
hardening (`no-new-privileges`, `cap_drop: ALL` otherwise) stays as-is; `grafana_data`
(the named volume) doesn't need root -- it's a normal Docker-managed volume the stock
`grafana` user already owns. Same revisit conditions as prometheus's entry above.

## Tor Relay dashboard

The `tor-relay` Prometheus job scrapes the Tor relay's MetricsPort on the operator host
(`172.16.9.10:9035`, Borg to operator only). The "Tor Relay" dashboard (folder "Tor") shows
relay flags, traffic against the 3000 KBytes/s rate limit, connections and circuits, and
saturation (onion-skin drops, rate-limit, TCP exhaustion, OOM, DoS counters).

It is file-provisioned from `dashboards/tor-relay.json` via `grafana_dashboards.yml`
(`allowUiUpdates: false`), so edit the JSON in the repo, not the Grafana UI; UI edits cannot
be saved. Tor does not expose uptime, version or CPU via MetricsPort; use Beszel for the
operator container's CPU and uptime.

### Tor Relay dashboard rollback

To remove the dashboard and the scrape job:

1. Remove the two grafana mounts (provider file and dashboards dir) from `docker-compose.yml`.
2. Remove `grafana_dashboards.yml` and the `dashboards/` directory.
3. Recreate grafana. If the dashboard lingers, delete it in the Grafana UI (the provider sets `disableDeletion`, so Grafana may keep it in its database).
4. Remove the `tor-relay` job from `prometheus.yml` and restart prometheus.

### Deploying changes to Borg

See "Storage layout on Borg" below: the compose file lives in the Compose Manager project
on `/boot`, every other file is a COPY under `/mnt/disks/appdataAndDocker/appdata`. After
merging a change here, copy the changed files to their locations by hand. Compose,
prometheus and provider changes need the container recreated or restarted; a dashboard
JSON change alone is picked up by Grafana's provisioning poll.

## Storage layout on Borg

Config and data live on Borg's `appdataAndDocker` drive, not on the `/boot` USB flash
drive and not in Docker named volumes. Only the compose file stays in the Compose Manager
project directory (it must).

```
/boot/config/plugins/compose.manager/projects/monitoring/
  docker-compose.yml                  (and .env)
/mnt/disks/appdataAndDocker/appdata/
  prometheus/
    etc/prometheus.yml                <- prometheus.yml
    data/                             (TSDB data)
  grafana/
    data/                             (grafana.db etc.)
    provisioning/
      datasources/datasources.yml     <- grafana_datasources.yml
      dashboards/dashboards.yml       <- grafana_dashboards.yml
    dashboards/                       <- dashboards/*
  snmp-exporter/
    snmp.yml                          <- snmp.yml
```

These are copies of the files in this folder, not a git checkout, so after merging a
change here the files must be copied over by hand.

The `user: "0:0"` / `DAC_OVERRIDE` settings on prometheus and grafana were a workaround
for the FAT `/boot` layout and are probably no longer needed now that everything is on
this drive. Removing them is deferred to a separate change.

### Migration from the old layout (one time)

Run on Borg as root/sudo. `PD` is the project dir, `A` is the appdata root.

```
PD=/boot/config/plugins/compose.manager/projects/monitoring
A=/mnt/disks/appdataAndDocker/appdata
```

1. Create the target dirs (`$A/prometheus/etc` and `/data` already exist, empty):
   ```
   mkdir -p $A/prometheus/etc $A/prometheus/data $A/grafana/data \
     $A/grafana/provisioning/datasources $A/grafana/provisioning/dashboards \
     $A/grafana/dashboards $A/snmp-exporter
   ```
2. Stop only prometheus and grafana:
   ```
   docker stop prometheus grafana
   ```
3. Copy the data while stopped, preserving ownership and modes:
   ```
   cp -a /var/lib/docker/volumes/monitoring_stack_prometheus_data/_data/. $A/prometheus/data/
   cp -a /var/lib/docker/volumes/monitoring_stack_grafana_data/_data/. $A/grafana/data/
   ```
4. Copy the configs from `$PD`:
   ```
   cp $PD/prometheus.yml $A/prometheus/etc/prometheus.yml
   cp $PD/grafana_datasources.yml $A/grafana/provisioning/datasources/datasources.yml
   cp $PD/grafana_dashboards.yml $A/grafana/provisioning/dashboards/dashboards.yml
   cp -r $PD/dashboards/. $A/grafana/dashboards/
   cp $PD/snmp.yml $A/snmp-exporter/snmp.yml
   ```
5. Keep a backup of the old compose file, install the new one (copy the merged
   `docker-compose.yml` from this folder over `$PD/docker-compose.yml`), then bring up
   ONLY the monitoring project (never `borg-stack`):
   ```
   cp $PD/docker-compose.yml $PD/docker-compose.yml.bak-pre-appdata
   # copy the new docker-compose.yml into $PD, then:
   docker compose -f $PD/docker-compose.yml -p monitoring_stack up -d
   ```
   This recreates prometheus, grafana and snmp-exporter (their mounts changed).
6. Verify: all Prometheus targets are up (`http://<borg-ip>:9090/targets`), the Grafana
   dashboards are present, and data history is intact (query a timestamp from before the
   migration).
7. Rollback: restore the backup and recreate:
   ```
   cp $PD/docker-compose.yml.bak-pre-appdata $PD/docker-compose.yml
   docker compose -f $PD/docker-compose.yml -p monitoring_stack up -d
   ```
   The old named volumes and the old files on `/boot` are left untouched until Kolin
   deletes them.
