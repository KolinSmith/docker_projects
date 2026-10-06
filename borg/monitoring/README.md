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
