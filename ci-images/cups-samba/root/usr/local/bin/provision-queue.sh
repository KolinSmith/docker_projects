#!/bin/sh
# One-shot (run by supervisord). Waits for cupsd, then creates the print queue
# from the PRINTER_* env vars if it doesn't already exist. Always exits 0 so a
# missing/duplicate queue never crash-loops the container.
#
#   PRINTER_NAME  queue name, e.g. Brother_Printer
#   PRINTER_URI   device URI, e.g. usb://Brother/HL-L2320D%20series?serial=XXXX
#   PRINTER_PPD   one of:
#                   - a CUPS model string for `lpadmin -m`
#                     (default: drv:///brlaser.drv/brl2320d.ppd  <- HL-L2320D)
#                   - an absolute path to a .ppd file (uses `lpadmin -P`)
#                   - "everywhere" (driverless IPP; not valid for usb:// URIs)
set -u

log() { echo "[provision-queue] $*"; }

PRINTER_NAME="${PRINTER_NAME:-}"
PRINTER_URI="${PRINTER_URI:-}"
PRINTER_PPD="${PRINTER_PPD:-drv:///brlaser.drv/brl2320d.ppd}"

if [ -z "$PRINTER_NAME" ] || [ -z "$PRINTER_URI" ]; then
    log "PRINTER_NAME / PRINTER_URI not set — leaving queue management to the CUPS web UI"
    exit 0
fi

# wait for cupsd to accept connections (max ~45s)
i=0
while ! lpstat -r >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -gt 45 ]; then
        log "cupsd did not come up — giving up (add the queue manually)"
        exit 0
    fi
    sleep 1
done

if lpstat -p "$PRINTER_NAME" >/dev/null 2>&1; then
    log "queue '$PRINTER_NAME' already exists — leaving it as-is"
    exit 0
fi

# `lpstat -r` can succeed a beat before cupsd will accept admin writes (it drops
# the first connections with "Bad file descriptor" during startup), so retry.
# NB: no `-E` on lpadmin — after `-p` it forces TLS on the local socket and fails.
add_queue() {
    if [ -f "$PRINTER_PPD" ]; then
        lpadmin -p "$PRINTER_NAME" -v "$PRINTER_URI" -P "$PRINTER_PPD" -o printer-is-shared=true
    elif [ "$PRINTER_PPD" = "everywhere" ]; then
        lpadmin -p "$PRINTER_NAME" -v "$PRINTER_URI" -m everywhere -o printer-is-shared=true
    else
        lpadmin -p "$PRINTER_NAME" -v "$PRINTER_URI" -m "$PRINTER_PPD" -o printer-is-shared=true
    fi
}

log "adding queue '$PRINTER_NAME' -> $PRINTER_URI  (ppd: $PRINTER_PPD)"
n=0
while [ "$n" -lt 6 ]; do
    n=$((n + 1))
    if add_queue 2>/tmp/lpadmin.err; then
        break
    fi
    if [ "$n" -eq 4 ] && [ "$PRINTER_PPD" != "everywhere" ] && [ ! -f "$PRINTER_PPD" ]; then
        log "model '$PRINTER_PPD' not taking — falling back to -m everywhere"
        PRINTER_PPD=everywhere
    fi
    log "lpadmin attempt $n failed ($(cat /tmp/lpadmin.err 2>/dev/null)); retrying"
    sleep 2
done

if ! lpstat -p "$PRINTER_NAME" >/dev/null 2>&1; then
    log "ERROR: could not create queue '$PRINTER_NAME' after $n attempts — add it via the web UI"
    exit 0
fi

cupsenable "$PRINTER_NAME" 2>/dev/null || true
cupsaccept "$PRINTER_NAME" 2>/dev/null || true
log "CUPS queue '$PRINTER_NAME' ready"

# Publish it over SMB with an explicit stanza (the bare [printers] auto-share
# doesn't reliably enumerate CUPS queues in this minimal container).
mkdir -p /etc/samba/smb.conf.d
cat > /etc/samba/smb.conf.d/printer.conf <<EOF
[${PRINTER_NAME}]
   comment = ${PRINTER_NAME}
   path = /var/spool/samba
   printer name = ${PRINTER_NAME}
   printable = yes
   guest ok = yes
   browseable = yes
   read only = yes
EOF
smbcontrol smbd reload-config >/dev/null 2>&1 || true
log "SMB printer share '${PRINTER_NAME}' published"
exit 0
