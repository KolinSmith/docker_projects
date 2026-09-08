# cups-samba — CUPS + Avahi + Samba print server in one image.
#
# For `printserver` (192.168.9.11, Raspberry Pi 3B running 64-bit Raspberry Pi
# OS Bookworm Lite). Built by .forgejo/workflows/build-cups-samba-image.yml and
# pushed to 100.86.4.29:3001/dax/docker_projects/cups-samba.
#
# Runs with `network_mode: host` (so mDNS/DNS-SD and NetBIOS/WS-Discovery reach
# the LAN) and the USB printer passed through via `devices: /dev/bus/usb`.
# supervisord (PID 1) runs: dbus, cupsd, avahi-daemon, smbd, nmbd, wsdd.
#
# Plan: dotfiles/.claude/plans/2026-09-07-cups-samba-image.md

FROM debian:bookworm-slim

LABEL org.opencontainers.image.source="https://git.hiddenba.se/dax/docker_projects"
LABEL org.opencontainers.image.description="CUPS + Avahi + Samba print server (Brother HL-L2320D / brlaser)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cups \
        cups-client \
        cups-filters \
        cups-ipp-utils \
        printer-driver-brlaser \
        avahi-daemon \
        avahi-utils \
        libnss-mdns \
        dbus \
        samba \
        samba-common-bin \
        wsdd \
        supervisor \
        ca-certificates \
        procps \
    && rm -rf /var/lib/apt/lists/*

# Baked config + scripts (see root/ tree)
COPY root/ /

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/provision-queue.sh \
    && usermod -aG lpadmin root \
    && mkdir -p /run/cups /run/dbus /run/samba /var/spool/samba \
        /var/log/supervisor /var/lib/samba/printers \
    && chmod 1777 /var/spool/samba \
    # Snapshot the built /etc/cups so the entrypoint can re-seed it when the
    # `./cups:/etc/cups` bind mount shadows the image with an empty dir.
    && cp -a /etc/cups /opt/cups-default

# Informational only under `network_mode: host`:
#   631/tcp  IPP        5353/udp mDNS (AirPrint)
#   445/tcp  SMB        137-138/udp NetBIOS
#   139/tcp  SMB        3702/udp WS-Discovery
EXPOSE 631/tcp 445/tcp 139/tcp 137/udp 138/udp 5353/udp 3702/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
