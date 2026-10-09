# icloudpd — iCloud Photos backup on borg

[`icloud-photos-downloader`](https://github.com/icloud-photos-downloader/icloud_photos_downloader)
in a container. Incrementally pulls the iCloud Photo Library to borg —
**originals, EXIF, RAW, Live Photos** — on a `--watch-with-interval` loop.

Chosen because Google's Photos API no longer allows third-party full-library
backup (since 2025-03-31), which killed the old `gphotos-sync` containers.
iCloud has no official API either, but `icloudpd` uses the iCloud.com
endpoints and works well.

## What it does / doesn't do

- **Add-only.** No `--auto-delete` — a photo removed from iCloud stays in the
  backup.
- Writes to `/mnt/user/media/iCloudPhotos/<year>/<month>/<day>/` — a **real,
  pre-existing backup location** discovered 2026-10-02, not a fresh directory.
  It already holds 244GB of real photos spanning 2008 through 2026-03-17, from
  an earlier icloudpd setup (never committed to this repo) that stopped when
  its Apple 2FA session expired and nobody re-authenticated. Confirmed
  `/mnt/disks/HUB/BACKUPS/iCloud_Backup` is already an exact mirror of this
  directory (identical files/timestamps), so it's already covered off-site —
  deploying this PR just resumes the existing backup, it does not start a
  fresh multi-hundred-GB redownload.
- Session cookie + keyring live in
  `/mnt/disks/appdataAndDocker/appdata/icloudpd/config` and **must persist**.
  This directory already contained stale session files (`*.session`, `*.bak`)
  from the same prior setup, last touched 2026-03-17 — consistent with the
  last downloaded photo's date, confirming the old session's expiry is what
  actually stopped the backup. Those files are harmless to leave in place;
  icloudpd will treat the expired session as invalid and prompt for fresh
  auth via the web UI.

## First-run setup

1. On borg, in this project dir (the config dir and `/mnt/user/media/iCloudPhotos`
   already exist from the prior setup — no need to create them fresh):
   ```
   cp .env.example .env          # then edit: APPLE_ID, ICLOUDPD_WEBUI_PORT, WATCH_INTERVAL
   ```
   (`.env` sits next to `docker-compose.yml` — compose reads it for `${...}`
   interpolation; it's gitignored.)
2. Bring it up: `docker compose up -d` (or add the project in Compose Manager).
3. Open `http://borg:8579/` (the `ICLOUDPD_WEBUI_PORT`). Enter the Apple ID
   **password**, then the **2FA code** Apple texts/pushes. icloudpd stores the
   session in `/config` and starts syncing.
   - CLI alternative:
     `docker exec -it icloudpd icloudpd --username <APPLE_ID> --password <pw> --auth-only`
4. `docker logs -f icloudpd` — first pass downloads everything; later passes only
   fetch new/changed items.

## Re-auth (~every 60 days)

Apple's 2FA session expires. When it does, the container logs
`Missing 2FA / session expired` and pauses. Re-open the web UI, enter a fresh
2FA code, and it resumes. Nothing is lost in between — it just isn't pulling new
photos until you re-auth.

## Notes

- `--size=original` gets full-res; drop to `adjusted`/`medium` only to save
  space.
- To also grab a second family Apple ID, copy this project dir, change
  `container_name`, `APPLE_ID`, the web-UI port, and the `/data` subpath.
- If a `--password-provider` / `--mfa-provider` flag name has drifted in a newer
  image, fall back to the `--auth-only` CLI step in setup #3 and drop those two
  flags from the compose `command:`.
