# docker_projects
Home base for all my docker compose files.

## CI

Forgejo Actions (`.forgejo/workflows/`). This instance (Forgejo 15.0.3) does not
serve workflow status badges, so they're listed here instead — check the repo's
**Actions** tab for live state.

| Workflow | File | Trigger | Does |
|---|---|---|---|
| Validate | `validate.yml` | every PR | yamllint + checkov + gitleaks on changed files; `scc` code-stats comment (PR-scoped) |
| Build CI image | `build-ci-image.yml` | push to `master` under `ci-images/ci-tools/**`, `v*.*.*` tags, manual | builds + pushes `100.86.4.29:3001/dax/docker_projects/ci-tools` (the image every `validate.yml` job runs in) |
| Build cups-samba image | `build-cups-samba-image.yml` | push to `master` under `ci-images/cups-samba/**`, `v*.*.*` tags, manual | builds + pushes `100.86.4.29:3001/dax/docker_projects/cups-samba` (the print-server image on `printserver`) |

Both image builds run on the arm64 `forgejo-runner`, push over plain HTTP to the
Tailscale-only registry, and disable buildx provenance/SBOM (the attestation
manifests 401 on that registry).

**Registry auth:** the login uses the per-run `${{ github.token }}` with
`permissions: packages: write` — no hand-made token to expire. If a build fails
at *"registry login failed"*, the instance isn't granting `packages: write` to
the Actions token; fix it in **Site Administration → Actions** (or per-repo
Settings), or fall back to a rotated `FORGEJO_TOKEN` secret + a
`-u <user> -p <token>` login. (The builds were previously breaking here — a ~50s
failure at `docker login`, not a build problem — because `secrets.FORGEJO_TOKEN`
had expired.)
