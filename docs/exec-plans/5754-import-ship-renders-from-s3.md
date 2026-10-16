# Import ship renders automatically from s3://fltyrd-sc/ship-views

Working plan for #5754. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A daily sidekiq-scheduler job reads `ship-views/index.json`, and for every changed ship attaches the new or changed views and holos to the model by slug, with the same cropping and holo measuring as the admin folder upload.

## Open questions
- None.

## What changed

### Phase 1 — Shared filename mapping
1. Move the `fieldFor` cases out of `mapping.spec.ts` into `test/fixtures/files/ship_view_filenames.json` (named groups of `filename → field|null`), read by `mapping.spec.ts` via `readFileSync`.
2. Port `fieldFor` to Ruby (`app/lib/ship_views/field_mapping.rb` or similar): same regexes, `VIEWPOINTS` (incl. `side` → port), extension lists, `textured` only for flight. Returns the snake_case attachment name.
3. Minitest reads the same JSON and asserts every case (camelCase field → underscored).

### Phase 2 — Bucket reader
1. `ScData::ShipViewsStore < ScData::ObjectStore` with prefix `ship-views`, reusing settings and client.
2. `index` and `files_for(path)` read a JSON object body via `get_object(...).body.read`, which is new in ObjectStore. `open(path)` streams a file for `attach(io:)`.

### Phase 3 — Import job
1. Migration: `models.ship_views_digest` (string) and `models.ship_view_md5s` (jsonb, default `{}`) — see the md5 decision in #5754.
2. `ScData::ShipViewsImportJob` (queue `loaders`): returns early unless configured. Reads the index and skips ships whose `files` digest equals `ship_views_digest`. Looks each ship up by `slug`, logs and skips unknown slugs. Maps each file with `fieldFor`, skips files whose md5 equals `ship_view_md5s[field]`, and attaches the changed ones with `io:`. It never detaches anything, then stores the digest and the md5s of what it attached.
3. Attach through `update_with_facts`/`save`, so `ActiveStorageVariants` (trim → `TrimAttachmentJob`) and `measure_attached_holos` run as they do for the folder upload.
4. Log one summary line per model (`slug: field, field`) and a run total.
5. Add it to `config/sidekiq_schedule.yml` with `enabled: <%= ScData::ShipViewsStore.configured? %>`.

### Phase 4 — Tests
1. Store test with `Aws::S3::Client.new(stub_responses: true)` like `raw_store_test.rb`.
2. Job tests: unchanged digest skipped, unknown slug skipped, unchanged md5 not re-attached, unlisted field untouched, trim job enqueued, digest stored.

## Intent Verification

- [ ] **Unchanged ships cost one GET** — a run with matching digests issues only the `index.json` request.
- [ ] **Unknown slugs are logged and skipped** — no error, the rest of the run continues.
- [ ] **Mapping cannot drift** — Vitest and Minitest assert the same JSON cases.
- [ ] **Only changed files attach** — a file whose md5 matches the stored one is not re-attached, even after its view was cropped.
- [ ] **Nothing is detached** — a field the listing doesn't mention keeps its attachment.
- [ ] **Views get cropped** — `TrimAttachmentJob` is enqueued for attached views; holos get `MeasureHoloJob`.
- [ ] **Run summary in the log** — each attached model and its fields.

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/object_store.rb` | S3 settings, client, `configured?`, injection for tests |
| `app/lib/sc_data/raw_store.rb` | Subclass precedent; md5-vs-etag `current?` |
| `app/frontend/admin/components/Models/ViewsFolderUpload/mapping.ts` | `fieldFor` to port |
| `app/frontend/admin/components/Models/ViewsFolderUpload/mapping.spec.ts` | Cases to move to the shared fixture |
| `app/models/model.rb` | View/holo attachments, `trim_attachment`, `measure_attached_holos` |
| `app/models/concerns/active_storage_variants.rb` | Trim / preprocess callbacks on save |
| `app/lib/attachment_trimmer.rb` | Replaces padded views' blobs, hence the stored md5 map |
| `app/jobs/sc_data/check_job.rb` | Scheduled sc_data job precedent (fails closed) |
| `config/sidekiq_schedule.yml` | Schedule entry |
| `test/lib/sc_data/raw_store_test.rb` | S3 stubbing pattern |

## Not in scope (deferred)
- **Removing the manual folder upload** — still needed for one-off fixes and for ships not in the bucket.

## Discovery Log

- **2026-10-16** Unknown slugs are checked against the index before `files.json` is read, since the digest lives on the model. A render whose download doesn't match its listed md5 is skipped, and the ship keeps its old digest so the next run retries it. A render whose md5 equals the current blob checksum (uploaded by hand before the bucket existed) is recorded rather than re-attached.
- **2026-10-16** Initial research and plan creation. Trimming replaces the blob, so the blob checksum doesn't identify the source file for cropped views.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
