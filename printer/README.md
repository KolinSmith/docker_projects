# printer

Docker stack for the print server (`printserver`, 192.168.9.11 — a Raspberry
Pi 3B). Deployed by `ansible_projects` `deploy_docker_env`
(`deploy_docker_services_for: printer`); `.env` is rendered from
`ansible_projects/roles/deploy_docker_env/templates/printer.env.example`.

## Services

| container | what |
|---|---|
| `cups` | CUPS (IPP :631) + Avahi (mDNS / AirPrint), host networking, the Brother HL-L2320D passed through on USB. Config persists in `./cups`. |
| `beszel-agent` | Monitoring agent, reports to the hub on voyager (`:45876`). |
| `beszel-socket-proxy` | Read-only Docker socket for the agent's container stats. |

## First run

1. `deploy_docker_env` clones this repo to the host and writes `~/docker/`.
2. Register `printserver:45876` in the Beszel hub UI on voyager.
3. `cd ~/docker && docker compose up -d`
4. Add the printer queue: CUPS web UI at `http://printserver:631` (login
   `CUPS_ADMIN_USER` / `CUPS_ADMIN_PASSWORD`), or
   `lpadmin -p Brother_Printer -E -v 'usb://Brother/HL-L2320D%20series?serial=U63877J0N376391' -m 'drv:///brlaser.drv/br2320d.ppd' -o printer-is-shared=true`
   (the `cups-server` image ships `printer-driver-brlaser`).

## Clients

- **Mac / Linux / iOS** — auto-discover via AirPrint/Bonjour, or IPP
  `http://printserver:631/printers/Brother_Printer`.
- **Windows** — add an IPP printer by that same URL (no SMB share).

## Notes

- USB passthrough is set at container start. If the printer re-enumerates
  (unplug/replug, hub glitch), `docker restart cups`.
- Both this box and the hub are on the `192.168.9.x` VLAN — no pfSense rule
  needed for `:45876`.
