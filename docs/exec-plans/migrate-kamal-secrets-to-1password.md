# Migrate Kamal Secrets to 1Password

**Status: Complete**

Deployment secrets migrated from plain-text `.env` files to 1Password. All secrets are fetched via `op read` at deploy time using a service account token.

## Key learnings

- Kamal uses Dotenv parsing for secrets files, NOT bash — `$DESTINATION` is not available. Per-environment secrets must go in `secrets.live` / `secrets.stage`, not `secrets-common`.
- 1Password item field names must not clash with built-in fields (e.g., "Login" items have a built-in `username` field — adding another causes ambiguity errors).
- Bash variable expansion: `$DESTINATION_user` is parsed as variable `$DESTINATION_user`, not `$DESTINATION` + `_user`. Use `${DESTINATION}_user`.
- `HCLOUD_TOKEN` must be exported in the CI shell before `kamal` runs because Kamal evaluates ERB deploy configs (which call `hcloud`) before loading secrets files.

## Final structure

### `.kamal/secrets-common` (shared secrets only)
- `S3_ACCESS_KEY_ID` / `S3_SECRET_ACCESS_KEY` via `op read`

### `.kamal/secrets.live` and `.kamal/secrets.stage` (per-environment)
- `HCLOUD_TOKEN`, `KAMAL_REGISTRY_USERNAME`, `KAMAL_REGISTRY_PASSWORD`
- `RAILS_MASTER_KEY`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- `DATABASE_URL`, `REDIS_URL` (computed from above)

### CI (`.github/workflows/deploy.job.yml`)
- Installs `op` CLI
- Single secret: `OP_SERVICE_ACCOUNT_TOKEN`
- Exports `HCLOUD_TOKEN` via `op read` before running kamal

## Post-merge cleanup

- Delete local `.env.live` and `.env.stage`
- Remove old GitHub Actions secrets: `HCLOUD_TOKEN`, `RAILS_MASTER_KEY`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`
- Keep `SSH_KEY` (CI infrastructure)
