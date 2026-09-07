# cups-samba

One image: **CUPS + Avahi + Samba + wsdd**, for the homelab print server
(`printserver`, 192.168.9.11 — a Raspberry Pi 3B on 64-bit Raspberry Pi OS
Bookworm Lite). Replaces the off-the-shelf `anujdatar/cups-server` image, which
has no Samba.

Built by `.forgejo/workflows/build-cups-samba-image.yml` (same pattern as
`ci-images/ci-tools`) → `100.86.4.29:3001/dax/docker_projects/cups-samba`,
tags `:latest` + `:sha-XXXXXXX` (+ semver on a `v*.*.*` tag). **arm64 only.**

Plan: `dotfiles/.claude/plans/2026-09-07-cups-samba-image.md`.
Consumed by: `docker_projects/printer/docker-compose.yml`.

## What runs inside

`supervisord` (PID 1) → `dbus`, `cupsd`, `avahi-daemon`, `smbd`, `nmbd`, `wsdd`,
plus a one-shot `provision-queue.sh` that adds the print queue on first start.

## Run

Needs `network_mode: host` (mDNS/DNS-SD + NetBIOS/WS-Discovery on the LAN) and
the USB printer passed through.

```yaml
services:
  cups:
    image: 100.86.4.29:3001/dax/docker_projects/cups-samba:latest
    network_mode: host
    devices:
      - /dev/bus/usb:/dev/bus/usb
    environment:
      CUPS_ADMIN_USER: print
      CUPS_ADMIN_PASSWORD: ${CUPS_ADMIN_PASSWORD}
      PRINTER_NAME: Brother_Printer
      PRINTER_URI: usb://Brother/HL-L2320D%20series?serial=U63877J0N376391
      PRINTER_PPD: drv:///brlaser.drv/brl2320d.ppd
    volumes:
      - ./cups:/etc/cups          # queue config persists here
```

## Environment

| var | default | purpose |
|---|---|---|
| `CUPS_ADMIN_USER` | `print` | web UI / `lpadmin` login (added to group `lpadmin`) |
| `CUPS_ADMIN_PASSWORD` | — | required for admin; unset = no usable web login |
| `PRINTER_NAME` | — | queue name; unset = manage queues by hand in the web UI |
| `PRINTER_URI` | — | device URI (`usb://…`); required with `PRINTER_NAME` |
| `PRINTER_PPD` | `drv:///brlaser.drv/brl2320d.ppd` | CUPS `-m` model string, **or** an absolute `.ppd` path (`-P`), **or** `everywhere` |

> The Brother **HL-L2320D** model string is `drv:///brlaser.drv/brl2320d.ppd`
> (note the `l` — `brl2320d`, not `br2320d`).

## Clients

- **macOS / iOS / Linux** — auto-discovered (AirPrint / Bonjour), or IPP at
  `http://printserver:631/printers/Brother_Printer`.
- **Windows** — `\\printserver\Brother_Printer` (guest, no login), or add an IPP
  printer by that same URL. `wsdd` makes it show up under *Network* in Explorer.

## Notes

- The host OS must **not** run its own `avahi-daemon` (port 5353 clash) — the
  Ansible provisioning masks it on `printserver`.
- USB is bound at container start. If the printer re-enumerates
  (unplug/replug), `docker restart cups`.
- Queue config lives in the `./cups` bind mount; wiping it makes
  `provision-queue.sh` re-create the queue from the env vars on next start.
