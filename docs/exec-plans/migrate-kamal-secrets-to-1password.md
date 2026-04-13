# Migrate Secrets to 1Password

**Status: Complete**

All secrets are managed via 1Password. No secret values are stored on disk.

## Development environment

Secrets are injected at runtime via `op run --env-file=.env.tpl` — nothing is written to disk.

- `.env.tpl` — checked into git, contains non-secret defaults and `op://` references for secrets
- `.env.local` — gitignored, worktree overrides (ports, DB suffix, etc.)
- `bin/dev` — wraps foreman with `op run` automatically
- `bin/credentials <env>` — edit Rails encrypted credentials via 1Password (opens in VS Code)

```bash
bin/dev                        # start dev server (secrets injected via op run)
bin/credentials production     # edit production credentials
bin/credentials staging        # edit staging credentials
```

**Prerequisites:** 1Password CLI (`op`) must be installed and you must be signed in to the "Fleetyards" vault.

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

## Editing Rails credentials

Rails credentials are edited via `bin/credentials`, which fetches the encryption key from 1Password so you don't need local `.key` files.

```bash
bin/credentials production   # edit config/credentials/production.yml.enc
bin/credentials staging      # edit config/credentials/staging.yml.enc
```

The script opens the decrypted credentials in VS Code and waits for you to save and close before re-encrypting.

**Prerequisites:** 1Password CLI (`op`) must be installed and you must be signed in to the "Fleetyards" vault.

## Post-merge cleanup

- Delete local `.env.live` and `.env.stage`
- Remove old GitHub Actions secrets: `HCLOUD_TOKEN`, `RAILS_MASTER_KEY`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`
- Keep `SSH_KEY` (CI infrastructure)
