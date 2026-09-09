#!/bin/sh
# PID 1. Prepares runtime dirs + the CUPS admin login, then hands off to
# supervisord which runs the daemons (and the one-shot queue provisioner).
set -eu

log() { echo "[entrypoint] $*"; }

CUPS_ADMIN_USER="${CUPS_ADMIN_USER:-print}"
CUPS_ADMIN_PASSWORD="${CUPS_ADMIN_PASSWORD:-}"

# --- runtime dirs --------------------------------------------------------
mkdir -p /run/cups /run/dbus /run/samba /var/spool/samba \
         /var/run/avahi-daemon /var/log/supervisor
chmod 1777 /var/spool/samba
dbus-uuidgen --ensure

# --- seed /etc/cups if a bind mount left it empty ----------------------
# The compose stack mounts `./cups:/etc/cups` for queue persistence; on first
# run that host dir is empty and shadows the image's baked config, so cupsd
# starts with no cups-files.conf / cupsd.conf and crash-loops. Re-seed from
# the snapshot taken at build time.
if [ ! -f /etc/cups/cups-files.conf ]; then
    log "/etc/cups is empty (bind mount) — seeding from /opt/cups-default"
    cp -a /opt/cups-default/. /etc/cups/
fi

# --- CUPS admin account -------------------------------------------------
# cups-files.conf: SystemGroup = root lpadmin. The web UI / lpadmin need a real
# account in group lpadmin.
if [ -n "$CUPS_ADMIN_PASSWORD" ]; then
    if ! id "$CUPS_ADMIN_USER" >/dev/null 2>&1; then
        log "creating CUPS admin user '$CUPS_ADMIN_USER'"
        useradd -r -M -d /nonexistent -s /usr/sbin/nologin -G lpadmin "$CUPS_ADMIN_USER"
    else
        usermod -aG lpadmin "$CUPS_ADMIN_USER" || true
    fi
    echo "${CUPS_ADMIN_USER}:${CUPS_ADMIN_PASSWORD}" | chpasswd
    log "CUPS admin login ready for '$CUPS_ADMIN_USER'"
else
    log "WARNING: CUPS_ADMIN_PASSWORD is unset — the web admin UI will have no usable login"
fi

log "starting supervisord"
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/cups-samba.conf
