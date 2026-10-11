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
