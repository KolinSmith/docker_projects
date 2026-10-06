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
