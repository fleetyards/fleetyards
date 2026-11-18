# Move ActiveStorage uploads from Hetzner Object Storage to Bunny Storage

Working plan for #6378. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Live uploads are written to and served from the `fltyrd-live-uploads` Bunny Storage zone, reached through a period in which every upload is written to both stores, and the Hetzner upload bucket is retired afterwards. sc_data and DB backups stay on Hetzner.

## Open questions

- **A copy outside Bunny once Hetzner is retired?** None, Bunny replication to a second region (covers a region, not a lost account), or a nightly copy to a third provider (e.g. Backblaze B2 / R2, a few euros a month). Decide before step 5.
- **How long to keep Hetzner as mirror after the switch?** Suggested: a few weeks without incidents.

## How it works

`config/storage.yml` defines `hetzner` and `bunny` as S3 services. With `BUNNY_S3__*` set, `cloud` is an ActiveStorage `Mirror`: uploads and variants go to the primary (`STORAGE_PRIMARY`, `hetzner` or `bunny`), `ActiveStorage::MirrorJob` (on the `storage` capsule) copies them to the other store, deletes go to both, and URLs come from the primary. Blobs keep `service_name = "cloud"`, so nothing in the database changes. `Overlay::Publisher` writes exports to every store and reads the published manifest from the primary. Without `BUNNY_S3__*`, `cloud` is plain Hetzner.

## Pull requests

| PR | Contents | Merge when |
|----|----------|------------|
| Infrastructure repo, Bunny uploads zone | S3 zone `fltyrd-<env>-uploads`, `BUNNY_UPLOADS_<ENV>`, `storage_origin` (all `hetzner`), storage cache rules | Merged, applied to stage and live |
| #6380 | Upload store settings through `Rails.app.creds`, `s3_region`, sc_data store on its own `SC_DATA_S3__*` | Now, no behaviour change |
| This branch | Mirror service, publisher to every store, `STORAGE_PRIMARY=hetzner` + `BUNNY_S3__*` for live and stage, idle rclone accessory | Step 1 |
| Infrastructure repo, stage flip | `storage_origin = "bunny"` for stage | Optional, for checking the stage zone through its pull zone |
| Infrastructure repo, live flip | `storage_origin = "bunny"` for live | Step 4, together with `STORAGE_PRIMARY=bunny` |
| Follow-up | `cloud` as plain Bunny S3, Hetzner upload settings, bucket, `uploads-copy` and pull zone fallback removed | Step 5 |

## Runbook

`bin/accessory-live` wraps `kamal accessory … -d live`.

### 1. Write to both stores

1. Merge #6380, deploy; check sc_data with a read-only runner on live (`ScData::ObjectStore.settings`, `ScData::ParsedStore.new(ScData::Source.environment).remote_checksum`).
2. Merge this PR, deploy. `cloud` is a mirror with Hetzner primary; nothing changes for users.
3. Check: a new upload and its variants exist in both stores (their blob keys in `fltyrd-live-storage` and `fltyrd-live-uploads`); `MirrorJob` runs on the `storage` queue without errors; an overlay export lands in both.

### 2. Copy what was there before

1. `bin/accessory-live boot uploads-copy`
2. Detached, so a dropped SSH session does not end it:
   ```sh
   bin/accessory-live exec uploads-copy --reuse "sh -c 'nohup rclone copy hetzner:fltyrd-live-storage bunny:fltyrd-live-uploads --metadata --size-only --transfers 32 --checkers 32 --tpslimit 200 --retries 5 --stats 1m --log-file /tmp/bulk.log >/dev/null 2>&1 &'"
   bin/accessory-live exec uploads-copy --reuse "tail -n 5 /tmp/bulk.log"
   ```
   About an hour for 362,659 objects / 96 GB (2026-11-17); `--tpslimit 200` stays under Bunny's 500 requests/s per zone. Run it when FSN1 is healthy.

### 3. Check both stores match

1. The `storage` queue has no `ActiveStorage::MirrorJob` waiting or retrying.
2. ```sh
   bin/accessory-live exec uploads-copy --reuse "rclone check hetzner:fltyrd-live-storage bunny:fltyrd-live-uploads --one-way --size-only"
   bin/accessory-live exec uploads-copy --reuse "rclone size hetzner:fltyrd-live-storage"
   bin/accessory-live exec uploads-copy --reuse "rclone size bunny:fltyrd-live-uploads"
   ```
   Nothing missing on the Bunny side. A rerun of the copy fixes any gap.

### 4. Switch

1. `STORAGE_PRIMARY: bunny` in `config/deploy.live.yml`, deploy. Uploads now land on Bunny first and are mirrored to Hetzner.
2. Merge the infrastructure live flip and run the live deploy workflow (approve after checking the plan shows `bunnynet_pullzone.storage` updated in place). Both stores hold everything, so the order of 1 and 2 does not matter and no request 404s in between.
3. Check: images via `storage.fltyrd.net` with the stored Content-Type, `overlay/live/manifest.json` with `max-age=300`, a new upload reachable through the CDN, AppSignal quiet for `Aws::S3::Errors::*` on user-facing actions.

**Rollback** at any point until step 5: `STORAGE_PRIMARY: hetzner` and the infrastructure flip reverted. Hetzner keeps receiving every upload through the mirror, so nothing has to be copied back.

### 5. Retire Hetzner for uploads (after the agreed period)

Follow-up PR: `cloud` becomes plain Bunny S3 (no mirror), the `hetzner` service, `s3_*` upload settings and `uploads-copy` accessory go, `bin/download-uploads` reads from the Bunny zone; in the infrastructure repo the Hetzner upload bucket and the `storage_origin` switch go. Then close the Hetzner `Aws::S3::Errors::*` incidents in AppSignal.

## Intent Verification

- [ ] **Both stores during the move** — a new upload, its variants and an overlay export exist in both stores while Hetzner is primary
- [ ] **Nothing lost** — `rclone check --one-way` finds nothing missing on Bunny before the switch
- [ ] **Served correctly after the switch** — images via `storage.fltyrd.net` return 200 with the stored Content-Type; the manifest is served with `max-age=300`
- [ ] **Rollback works** — `STORAGE_PRIMARY=hetzner` serves everything uploaded after the switch, without a copy
- [ ] **sc_data unaffected** — a sync after the deploy still reads and writes `fltyrd-sc`
- [ ] **Backups unaffected** — the next DB backup lands in `fltyrd-live-backups`

## Key files

| File | Role |
|------|------|
| `config/storage.yml` | `hetzner`, `bunny`, `cloud` as mirror with `STORAGE_PRIMARY` |
| `config/application.rb` | `MirrorJob` on the `storage` queue |
| `app/lib/overlay/publisher.rb` | Writes exports to every store of `cloud` |
| `config/initializers/content_security_policy.rb` | Direct uploads may go to either bucket |
| `config/deploy.yml`, `config/deploy.live.yml`, `config/deploy.stage.yml` | `STORAGE_PRIMARY`, `BUNNY_S3__*`, `uploads-copy` accessory |
| `.kamal/secrets-common`, `.kamal/secrets.live`, `.kamal/secrets.stage` | Bunny zone keys, rclone remotes |

## Not in scope (deferred)

- **Moving `fltyrd-sc`** — decided to stay on Hetzner (see issue).
- **Moving DB backups** — decided to stay on Hetzner (see issue).
- **Retiring the Hetzner upload bucket** — step 5, its own PR after the agreed period.

## Discovery Log

- **2026-11-17** Initial research and plan creation. Compatibility test, CDN header test, origin latency and request-rate measurements are in the issue.
- **2026-11-17** Second throwaway zone: virtual-hosted URLs work (a new zone's hostname takes under a minute to resolve to it; `NoSuchBucket` until then). Direct-upload preflight returns 204 with `Access-Control-Allow-Headers: *` and all methods. Anonymous GETs on the S3 endpoint are refused (403); every app URL goes through the blob/representation redirect controllers, which swap in the storage CDN host. Only `Overlay::Publisher.public_url` falls back to a raw bucket URL, when no storage CDN is configured.
- **2026-11-17** Stage has no servers (`web_servers_count = 0`), so stage is only used for checks against its zone.
- **2026-11-17** `Rails.app.creds` checks `ENV` before the encrypted credentials, so store settings can come from the deploy config. The sc_data store's fallback to the upload settings would have followed the uploads; #6380 removes it and sets `SC_DATA_S3__*` in production.
- **2026-11-17** Infrastructure applied to stage and live: zones `fltyrd-<env>-uploads` (S3, DE), `BUNNY_UPLOADS_<ENV>`. rclone and `s3cmd --region=de` write, read and list the zones with those credentials. Live apply needed two drift fixes first (SSH key re-added under a new ID, Volume tier on the live storage pull zone) and now waits for approval in the pipeline.
- **2026-11-18** Plan changed from a cutover to a mirror (write to both, copy history, switch when in sync), and Hetzner will be retired for uploads afterwards instead of kept as a nightly copy.
- **2026-11-18** Mirror checked against the stage stores with `STORAGE_PRIMARY=bunny`: upload lands on Bunny, `mirror` copies it to Hetzner byte-identical, URLs come from the Bunny bucket, the publisher lists Bunny then Hetzner, delete removes it from both. `STORAGE_PRIMARY=r2`, and `bunny` without `BUNNY_S3__*`, fail at boot with their messages; without `BUNNY_S3__*` `cloud` is plain Hetzner. The Hetzner-primary run hit an FSN1 outage (status page: "Object Storage in location fsn1 partially degraded"): every PUT returned 405 even from a bare client, and `storage.fltyrd.net` served 503 for uncached objects. The rerun once FSN1 answered again passed: with Hetzner primary the upload lands on Hetzner, `mirror` copies it to Bunny, URLs come from the Hetzner bucket, the publisher lists Hetzner then Bunny, delete removes it from both.

## Progress
- [x] Infrastructure: zones, 1Password items, cache rules on stage and live
- [x] #6380 ready
- [x] Mirror branch: storage config, publisher, deploy config, rclone accessory
- [x] Mirror checked against the stage stores with either primary
- [ ] Steps 1–4
- [ ] Step 5 follow-up
- [ ] Findings to `docs/findings/`, exec-plan deleted
