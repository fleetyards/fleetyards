# Compare: Short Share URL

## Problem
The compare page share button copies the current full URL, which looks like:

```
https://fleetyards.net/compare?models=anvil-aerospace-carrack&models=rsi-constellation-andromeda&models=drake-cutlass-black
```

With up to 8 ships allowed and long manufacturer-prefixed slugs, the link blows past most chat preview widths and is awkward to share. We already operate a short domain (`fltyrd.net` live, `fltyrd.dev` stage — `config/deploy.*.yml`, wired via `config/routes/short_routes.rb`), and we already have a `CompareImage` record per slug-set that stores the OG image. We can ride both pieces to produce a stable, opaque short link:

```
https://fltyrd.net/c/aB3xK9
```

## Current state

- **Compare URL today**: `/compare?models=<slug>&models=<slug>...`. Frontend reads via `useCompareModelFilters` → `useFilters` (`app/frontend/shared/composables/useFilters.ts`), which pulls straight from `route.query`. Backend reads via `compare_params` in `app/controllers/frontend/base_controller.rb:183`.
- **Short domain plumbing exists**: `config/routes/short_routes.rb` mounts a `:short` namespace on the short host. It already exposes `/sc` which 302s to the long compare URL but passes the same query params through — that just shortens the *host*, not the URL length. Useful for `h/:username` etc., not yet used by compare.
- **Share button**: `app/frontend/frontend/components/ShareBtn/index.vue` accepts a `url` prop and either calls `navigator.share` (mobile) or copies to clipboard. Compare page wires it in `app/frontend/frontend/components/Compare/Models/Form/index.vue:27-31`, where `shareUrl` is hardcoded to `window.location.protocol + host + route.fullPath`. Note: it ignores `short_domain` entirely today.
- **OG image record**: `CompareImage` (`app/models/compare_image.rb`) has a unique `slug_set` column. `CompareImage.for(models)` filters to `models_with_images`, prepends `STYLE_VERSION` ("v2"), sorts slugs, and joins with `-`. This is purpose-built for image caching: the version prefix lets us invalidate when the visual style changes, and the image-presence filter avoids attaching an empty composite.
- **Migration baseline**: latest migration timestamp is `20260526120000`; next should be at or after the current date.

## Design decisions

| Question | Decision | Why |
| --- | --- | --- |
| New table or extend `compare_images`? | **Extend `compare_images`** with a `share_key` (sorted full slug join, no version prefix) and a `short_code`. | Two tables would key on overlapping but non-identical slug sets and double the writes per comparison. One record per comparison stays simple. |
| Why a separate `share_key` instead of reusing `slug_set`? | `slug_set` is image-scoped: version-prefixed, and excludes models without a `store_image`. A share link must cover **all** compared slugs regardless of image state, and must stay stable across image style version bumps. Different concerns → different column. | |
| Short code shape | **8-char base62** (`SecureRandom.alphanumeric(8)`), uppercase+lowercase+digits. ~218 trillion values, no ambiguity issues at this scale, easy to type. | Shorter (6) feels nicer but collides earlier; UUIDs (`compare_images.id` is UUID) are too long. |
| Where is the short code minted? | **Lazily, on demand** via a small JSON endpoint the share button calls on click. Not on every compare page render. | Page render shouldn't write to DB just because someone visits `/compare`. Most visits never share. |
| Share-link route | `GET /c/:short_code` on the short-domain namespace → 302 to `frontend_compare_url(models: [...])`. | Matches the pattern of `sc`, `h/:username`, `fi/:token`. |
| What if short domain isn't configured (dev)? | Endpoint falls back to returning a normal long URL. Frontend treats the returned URL as opaque. | Keeps dev simple; `Rails.configuration.app.short_domain` is already checked elsewhere with the same fallback pattern (see `User#public_hangar_url`). |
| Slug normalization | Lowercase, accept both canonical `slug` and `legacy_slug` (matches what `compare_models` does today: `app/controllers/frontend/base_controller.rb:78-79`), resolve to canonical `slug` before building `share_key`. Empty/unknown slugs → 422. | Stable keying — two URLs with the same set of models (even if one used legacy slugs) should map to the same short code. |
| Capacity cap | Reject requests with > 8 slugs (matches the compare-page UI cap and the `.limit(8)` server-side). | Avoid unbounded payloads or absurd keys. |

## Steps

### 1. Migration
- Add `share_key :string` and `short_code :string` to `compare_images`. Both nullable initially (existing OG-image rows have no share lifecycle yet).
- Add `add_index :compare_images, :share_key, unique: true` (partial index `where: "share_key IS NOT NULL"`).
- Add `add_index :compare_images, :short_code, unique: true` (partial index `where: "short_code IS NOT NULL"`).

### 2. Model (`app/models/compare_image.rb`)
- Add `Self.find_or_create_for_share(model_slugs)`:
  - Resolve slugs → `Model.where(slug:).or(Model.where(legacy_slug:))`, dedupe, sort by canonical `slug`. Return `nil` if empty.
  - Build `share_key = canonical_slugs.join("-")` (no STYLE_VERSION; that's image-scoped).
  - `find_or_create_by!(share_key: share_key)`. On create, generate `short_code` via retry loop:
    ```ruby
    loop do
      candidate = SecureRandom.alphanumeric(8)
      break candidate unless CompareImage.exists?(short_code: candidate)
    end
    ```
    Save in the same write. Handle `ActiveRecord::RecordNotUnique` (collision under race) by re-finding.
  - Return the record.
- Add instance method `#share_url(host:)` that builds the short URL if `short_code` present, else falls back to the long URL — keeps the API contract clean for callers.
- Leave `STYLE_VERSION` and `slug_set` alone. `Self.for` (image generator) stays untouched.

### 3. Backfill maintenance task
Existing `compare_images` rows already have a `slug_set` from OG-image generation but no `share_key` — without backfilling, the first share for an already-rendered comparison would create a duplicate row. Fix this with a one-off Rake task that pre-populates `share_key` from the existing slug data, so future shares land on the existing row.

- New `lib/tasks/compare_images_backfill.rake` with `compare_images:backfill_share_keys`.
- Iterate `CompareImage.where(share_key: nil)` in `find_each` batches.
- For each row: strip the `STYLE_VERSION` prefix from `slug_set` (`slug_set.sub(/^#{STYLE_VERSION}-/, "")`), keep the resulting hyphen-joined slugs as `share_key`. Save.
- **Caveat**: `slug_set` excludes models without `store_image`, so a backfilled `share_key` only reflects image-bearing models. If a comparison contained a model with no image, the backfilled key won't match a future share request for the same comparison and the share endpoint will create a second row. That's an acceptable rare-case duplicate; we don't try to reconstruct the original input list. Note this in the task's docstring.
- Skip rows where `slug_set` has only one slug after stripping — a single-model "comparison" doesn't need a share key.
- Run in a single deploy: `bin/rails compare_images:backfill_share_keys`. Idempotent (skips rows that already have `share_key`).
- Do **not** mint `short_code` during backfill — codes are minted lazily on first actual share request. Backfill only populates `share_key` so the find-by-share_key lookup succeeds.

### 4. Public API endpoint
Add a tiny endpoint the share button calls. Two reasonable homes:

- **Preferred**: `POST /api/v1/compare/share` returning `{ short_url, long_url }`. Lives under `app/controllers/api/v1/compare_controller.rb`. Add the request schema to `api_components` (do **not** edit `swagger/schema.yaml` directly — see [[feedback_never_edit_schema_yaml]]) and run `./bin/generate-schema` after, followed by `bundle exec standardrb -A` and frontend lint per [[feedback_generate_schema]].
- Body: `{ "models": ["slug-a", "slug-b", ...] }` (max 8).
- Behavior: call `CompareImage.find_or_create_for_share`, respond with `{ short_url: record.share_url(host: Rails.configuration.app.short_domain), long_url: frontend_compare_url(models: canonical_slugs) }`. 422 on empty/oversized/unknown slug list.

Permissions: public, unauthenticated, no rate limit beyond whatever lives in `application_controller`. (We can add Rack::Attack throttling later if abused.)

### 5. Short route
In `config/routes/short_routes.rb`, add inside the `:short` namespace:

```ruby
get "c/:short_code", to: "base#model_compare_share", as: :model_compare_share, constraints: { short_code: /[A-Za-z0-9]{8}/ }
```

In `app/controllers/short/base_controller.rb`, add:

```ruby
def model_compare_share
  record = CompareImage.find_by(short_code: params[:short_code])
  if record.blank? || record.share_key.blank?
    redirect_to frontend_compare_url, allow_other_host: true
    return
  end

  slugs = record.share_key.split("-")
  redirect_to frontend_compare_url(models: slugs), allow_other_host: true
end
```

Note: existing `model_compare` (`/sc`) action stays — backwards-compat with any link already in the wild. Both work.

### 6. Frontend wiring
- Generate the API client binding via Orval (don't hand-write — `useCompareShare` will fall out of the schema once the api_components are in place).
- `app/frontend/frontend/components/Compare/Models/Form/index.vue`:
  - Replace the hardcoded `shareUrl` computed with a `shareUrl = ref<string | undefined>(undefined)` plus a click handler that, on first click, calls the new endpoint with `props.models.map(m => m.slug)`, stores `short_url`, then triggers the share/copy.
  - Pass an `onShare` callback into `ShareBtn` (new prop) that returns the URL to share. `ShareBtn` `await`s it before invoking `navigator.share` / clipboard. Falls back to the prop `url` if `onShare` is absent — keeps every other call site untouched.
  - Loading state: while the call is in-flight, disable the button and show the spinner that `ShareBtn` already supports via `loading`.
  - Failure: if the endpoint errors, fall back to the long URL (`route.fullPath` against `window.location.host`) so sharing always works.
- Use `pnpm` per [[feedback_use_pnpm]] for any frontend dep changes; standardrb per [[feedback_standardrb_not_rubocop]] for Ruby.

### 7. Tests
- **`spec/models/compare_image_spec.rb`**:
  - `find_or_create_for_share` resolves canonical slugs, dedupes, sorts, builds expected `share_key`, generates 8-char `short_code`.
  - Idempotent: same slug set (in any order, canonical or legacy slugs) returns the same record.
  - Empty / all-unknown slug list returns `nil`.
  - Collision retry: stub `SecureRandom.alphanumeric` to return a value already in the table, then a fresh one; assert the second is persisted.
- **`spec/requests/api/v1/compare/share_spec.rb`** (or wherever compare api specs would live):
  - Happy path returns `{ short_url, long_url }`, persists a record.
  - Repeated calls with the same models return the same `short_url`.
  - 9+ models → 422.
  - Unknown slug filtered, mixed known/unknown returns short URL for the known subset (or 422 if zero remain — pick one and assert).
- **`spec/requests/short/model_compare_share_spec.rb`**:
  - Valid short code → 302 to `frontend_compare_url(models: [...])` with the expected param order.
  - Unknown short code → 302 to bare `/compare`.
  - `short_code` regex constraint rejects wrong-length codes (routing miss = 404).

### 8. Verify in browser
Run the dev server, share a 3-ship comparison, follow the resulting `fltyrd.dev/c/<code>` URL, confirm it lands on the right `/compare?...` view. Repeat with 1 and 8 ships. Confirm clipboard contents and mobile `navigator.share` payload both look right.

## Out of scope
- Rate limiting / abuse protection for the share endpoint (note for follow-up if it ever shows up in logs).
- Reusing the same short-code mechanism for any other shareable page (hangar, fleet, model). Could be generalized later into a `ShortLink` polymorphic model; not justified today with only one use case.
- Pruning unused `compare_images` rows. They're cheap and the unique slug-set index keeps them deduped.
- Custom vanity codes.

## Risk notes
- **Race on first share**: two concurrent first-shares of the same `share_key` will race on the unique index. Rescuing `RecordNotUnique` and re-finding handles it; spec for it.
- **Two records, one comparison**: The backfill task (step 3) populates `share_key` on existing OG-image rows so future shares land on the same row instead of creating siblings. The rare case where backfill can't reconstruct a complete `share_key` (when the original comparison included a model without `store_image`) is called out in step 3 — that comparison ends up with two rows over its lifetime, which is acceptable.
- **Slug churn**: if a model's `slug` changes after a short code is minted, the redirect target's `?models=...` will contain the old slug. Compare's controller already accepts `legacy_slug`, so this keeps working, but we should resolve to current canonical slugs *in the redirect* (look up each slug at redirect time and use the canonical one) so users land on a clean URL. Trade-off: adds a DB lookup per redirect; acceptable.
- **Bot traffic**: the new endpoint is public and unauthenticated. Watch logs for abuse; add throttling if needed.
