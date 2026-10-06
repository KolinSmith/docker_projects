# Borg Monitoring Stack

Prometheus + Grafana + exporters for Borg, plus the Beszel agent (migrated from
`borg-stack` 2026-10-05 -- same key, same hub registration, just managed from this
compose file now instead).

## Deploy

1. Copy `.env.example` to `.env` and fill in real values.
2. `docker compose up -d`
3. Grafana: `http://<borg-ip>:3003`. Prometheus: `http://<borg-ip>:9090`.

See `docs/superpowers/specs/2026-10-05-borg-monitoring-stack-design.md` (dotfiles repo)
for the full design and rationale.

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
