# Migrate Kamal Secrets to 1Password

Deployment secrets are currently in plain-text `.env.live` / `.env.stage` files, manually sourced before running Kamal. Migrating to 1Password centralizes secrets, accessible via a single service account token (`OP_SERVICE_ACCOUNT_TOKEN`).

## Phase 1: Create 1Password items in `Fleetyards` vault

**Shared secrets** (single `credential` field):

| Item | Field |
|---|---|
| `HCLOUD_TOKEN` | `credential` |
| `KAMAL_REGISTRY_USERNAME` | `credential` |
| `S3_ACCESS_KEY_ID` | `credential` |
| `S3_SECRET_ACCESS_KEY` | `credential` |

**Per-environment secrets** (`live` and `stage` fields):

| Item | Fields |
|---|---|
| `KAMAL_REGISTRY_PASSWORD` | `live`, `stage` |
| `RAILS_MASTER_KEY` | `live`, `stage` |
| `POSTGRES_USER` | `live`, `stage` |
| `POSTGRES_PASSWORD` | `live`, `stage` |

Values come from the current `.env.live` and `.env.stage` files.

## Phase 2: Update `.kamal/secrets-common`

Replace env var passthrough with `op read` calls:

```bash
# All secrets are fetched from 1Password (vault: Fleetyards)
# Requires OP_SERVICE_ACCOUNT_TOKEN to be set in the environment

VAULT="Fleetyards"

# Shared secrets
HCLOUD_TOKEN=$(op read "op://$VAULT/HCLOUD_TOKEN/credential")
KAMAL_REGISTRY_USERNAME=$(op read "op://$VAULT/KAMAL_REGISTRY_USERNAME/credential")
S3_ACCESS_KEY_ID=$(op read "op://$VAULT/S3_ACCESS_KEY_ID/credential")
S3_SECRET_ACCESS_KEY=$(op read "op://$VAULT/S3_SECRET_ACCESS_KEY/credential")

# Per-environment secrets (DESTINATION is set by Kamal via -d flag)
KAMAL_REGISTRY_PASSWORD=$(op read "op://$VAULT/KAMAL_REGISTRY_PASSWORD/$DESTINATION")
RAILS_MASTER_KEY=$(op read "op://$VAULT/RAILS_MASTER_KEY/$DESTINATION")
POSTGRES_USER=$(op read "op://$VAULT/POSTGRES_USER/$DESTINATION")
POSTGRES_PASSWORD=$(op read "op://$VAULT/POSTGRES_PASSWORD/$DESTINATION")
```

No changes to `.kamal/secrets.live` or `.kamal/secrets.stage` — they compute `DATABASE_URL` and `REDIS_URL` from variables set by secrets-common.

## Phase 3: Update `.github/workflows/deploy.job.yml`

- Add step to install 1Password CLI (`op`) after `ruby/setup-ruby`
- Update "Fetch known hosts" step: replace `${{ secrets.HCLOUD_TOKEN }}` with `op read` using `OP_SERVICE_ACCOUNT_TOKEN`
- Replace all individual secret env vars in "Deploy with Kamal" step with single `OP_SERVICE_ACCOUNT_TOKEN`

## Phase 4: Update `.env.example`

Add comment documenting the 1Password deploy flow:

```
# Kamal deployment secrets are fetched from 1Password at deploy time.
# Set OP_SERVICE_ACCOUNT_TOKEN before deploying:
#   export OP_SERVICE_ACCOUNT_TOKEN="your-token"
#   kamal deploy -d live
```

## Phase 5: GitHub Actions secrets

- Add `OP_SERVICE_ACCOUNT_TOKEN` as a repository secret (before merging)
- After verification, remove old secrets: `HCLOUD_TOKEN`, `RAILS_MASTER_KEY`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`
- Keep `SSH_KEY` (CI infrastructure)

## Phase 6: Local cleanup

- Delete `.env.live` and `.env.stage` from local machines (already gitignored)

## Verification

1. `export OP_SERVICE_ACCOUNT_TOKEN=... && kamal config -d stage` — verify secrets resolve locally
2. Push to trigger a stage deploy via CI — confirm it succeeds
3. Confirm clean failure when `OP_SERVICE_ACCOUNT_TOKEN` is unset
