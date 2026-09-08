# printer

Docker stack for the print server (`printserver`, 192.168.9.11 — a Raspberry
Pi 3B on Armbian Debian 13 / Trixie, minimal arm64). Deployed by `ansible_projects`
`deploy_docker_env` (`deploy_docker_services_for: printer`); `.env` is rendered
from `ansible_projects/roles/deploy_docker_env/templates/printer.env.example`.

## Services

| container | what |
|---|---|
| `cups` | Custom `cups-samba` image (`ci-images/cups-samba/`): CUPS (IPP :631) + Avahi (mDNS / AirPrint) + Samba (`\\printserver\<queue>`) + wsdd, host networking, the Brother HL-L2320D passed through on USB. Queue config persists in `./cups`. |
| `beszel-agent` | Monitoring agent, reports to the hub on voyager (`:45876`). |
| `beszel-socket-proxy` | Read-only Docker socket for the agent's container stats. |

## First run

1. `deploy_docker_env` clones this repo to the controller and writes `~/docker/`
   on the host (compose + `.env`).
2. The host's Docker daemon trusts the plain-HTTP Forgejo registry over
   Tailscale — Ansible sets `{"insecure-registries": ["100.86.4.29:3001"]}`
   (`ansible_projects` PR #53). Ideally the `cups-samba` package is set
   **Public** in the Forgejo UI (then no auth is needed); until it is,
   `deploy_docker_env` runs a `docker login` for the printer host so the pull
   still works.
3. Register `printserver:45876` in the Beszel hub UI on voyager.
4. `cd ~/docker && docker compose up -d`
5. The `cups` image auto-creates the `PRINTER_NAME` queue from `PRINTER_URI` /
   `PRINTER_PPD` on first start. To do it by hand instead:
   `lpadmin -p Brother_Printer -v 'usb://Brother/HL-L2320D%20series?serial=U63877J0N376391' -m 'drv:///brlaser.drv/brl2320d.ppd' -o printer-is-shared=true`
   then `cupsenable Brother_Printer && cupsaccept Brother_Printer`.

## Clients

- **Mac / Linux / iOS** — auto-discover via AirPrint / Bonjour, or IPP
  `http://printserver:631/printers/Brother_Printer`.
- **Windows** — `\\printserver\Brother_Printer` (guest, no login), or add an IPP
  printer by that same URL. `wsdd` makes it appear under *Network* in Explorer.

## Notes

- USB passthrough is set at container start. If the printer re-enumerates
  (unplug/replug, hub glitch), `docker restart cups`.
- The host must NOT run its own `avahi-daemon` (5353 clash) — Ansible masks it.
- Both this box and the hub are on the `192.168.9.x` VLAN — no pfSense rule
  needed for `:45876`. Cross-VLAN printing (MAIN → 192.168.9.11 on 631/445/139
  + an mDNS reflector) is handled in the migration plan, not here.
