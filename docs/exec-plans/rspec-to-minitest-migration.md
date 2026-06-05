# Exec Plan: Migrate RSpec → Minitest

## Goal

Move the Ruby test suite from RSpec to Minitest in phases, keeping the suite green at every step and never breaking `swagger/schema.yaml` generation.

## Why incremental

The suite has 402 spec files:

| Group              | Files | Notes                                                              |
| ------------------ | ----- | ------------------------------------------------------------------ |
| `spec/requests/`   | 349   | All use `openapi-ruby` Style 1 (`path` / `run_test!`) — schema gen |
| `spec/jobs/`       | 23    | Plain RSpec                                                        |
| `spec/models/`     | 11    | Plain RSpec + `shoulda-matchers`                                   |
| `spec/loaders/`    | 8     | Plain RSpec                                                        |
| `spec/mailers/`    | 6     | ActionMailer tests                                                 |
| `spec/lib/`        | 4     | Plain RSpec                                                        |
| `spec/emails/`     | 1     | `email_processor_spec.rb`                                          |
| `spec/requests/omniauth_callbacks_spec.rb` | 1 | Plain request spec (no openapi DSL) |

The 349 `spec/requests/` files need structural restructuring — `openapi-ruby`'s Minitest adapter only exposes Style 2 (`api_path` at top, `assert_api_response` per test). That's not a mechanical rename, so we leave it for last and convert resource-by-resource. Everything else (~53 files) is straightforward and goes first.

## Decisions

- **Test style:** classic Minitest — `class FooTest < ActiveSupport::TestCase` + `test "..."` blocks. No `minitest-spec-rails`.
- **shoulda-matchers:** keep, reconfigure for `:minitest`.
- **Parallelism:** Rails' built-in `parallelize(workers: :number_of_processors)` replaces `flatware-rspec`.
- **Coexistence:** both runners live side-by-side during Phases 0–2. Final cleanup in Phase 3.
- **Fixtures-where-it-pays:** during migration, lift common "background" data (default user, common `Model`, `Manufacturer`, `Fleet`, etc.) from `FactoryBot.create` calls into Rails fixtures. Per-test entities under test stay as factories. See [Fixtures strategy](#fixtures-strategy).

## Fixtures strategy

Rails fixtures load **once per suite**, sit inside the per-test transaction wrapping, and don't pay the validation + callback + association cost on every single test. FactoryBot stays for the entity under test and anything we mutate, but everything else that's just "context" is a candidate.

### What moves to fixtures

Strong candidates — heavy graphs reused widely:

- `Manufacturer` records (handful, referenced by most ship tests).
- `Model` / a small set of canonical ships used as reference data.
- A default `User` + an `admin_user` used purely for `sign_in`.
- `OauthApplication` test client.

Stays in factories:

- The record being tested (we want a fresh, named-attribute build per test).
- Anything with `sequence(...)` for uniqueness across tests.
- Anything whose state we mutate (`record.update!(...)` in the test body).
- Anything where each test exercises a different trait combination.

### When to convert

Two passes, woven into existing phases — not a separate Phase 4:

1. **During Phase 1 conversion of each `spec/<folder>/`:** when you encounter the same `create(:foo, ...)` setup in ≥3 files, lift it to a fixture. Don't over-engineer for one-offs.
2. **During Phase 2 per-resource conversion:** request specs share more setup than unit tests do. Each resource conversion includes a "what does every test in this folder build that could be a fixture?" review.

### How to convert safely

1. Add `test/fixtures/<plural>.yml` with named records — keep names readable (`default_user`, not `user_1`).
2. Reference via `users(:default_user)` (or `@user = users(:default_user)` in `setup`).
3. **Benchmark per folder** — measure runtime of the folder before and after with `time bin/rails test test/<folder>`. If we don't see ≥10% improvement, the conversion isn't worth the readability cost; revert.
4. Fixtures bypass model callbacks. Audit any `before_validation` / `before_save` on the affected models; if the test relies on side effects of those callbacks, **don't** fixture it.

### Risks

- **Hidden callback dependencies.** Mitigated by per-folder benchmark + targeted review of model callbacks.
- **Stale fixtures drift from schema.** Add a CI step that loads fixtures into a fresh DB (`bin/rails db:fixtures:load`) — already implicit in `bin/rails test`.
- **Tests becoming coupled to fixture state.** Keep fixtures minimal; if a test needs a `user` with a specific trait, build it in the test, don't add `user_with_two_factor_enabled` to the YAML.

## Phase 0 — Coexistence setup

Wire up Minitest without touching any spec files. Both `bundle exec rspec` and `bin/rails test` work after this phase.

1. **Gemfile** — `test` group:
   - Add `gem "minitest"`, `gem "minitest-reporters"` (nicer output).
   - Keep `rspec-rails`, `flatware-rspec`, `shoulda-matchers`, `factory_bot_rails`.
2. **`test/test_helper.rb`** (new) — mirrors `spec/rails_helper.rb`:
   - Require Rails, env, sidekiq fake mode.
   - `parallelize(workers: :number_of_processors)`.
   - `include FactoryBot::Syntax::Methods`, `include ActiveSupport::Testing::TimeHelpers`.
   - Configure `shoulda-matchers` for Minitest + Rails.
   - Devise integration helpers (for integration tests).
   - OmniAuth test mode setup.
3. **`test/openapi_helper.rb`** (new) — `require "openapi_ruby/minitest"`.
4. **Factories:** keep `spec/factories/` in place; Minitest helper requires it via `FactoryBot.definition_file_paths`. (Avoids touching ~60 factory files until Phase 3.)
5. **CI:** add a `bin/rails test` step alongside the existing `bundle exec rspec` step. Both must pass.
6. **Smoke test:** add `test/models/smoke_test.rb` that asserts true. Verify locally and in CI.

**Verify:** `bin/rails test` runs and passes the smoke test; `bundle exec rspec` still runs the full suite.

## Phase 1 — Non-API specs (~53 files)

Migrate one folder at a time. Delete the `*_spec.rb` file in the same commit that creates its `*_test.rb` replacement.

Order (smallest → largest blast radius):

1. `spec/lib/` (4) → `test/lib/`
2. `spec/emails/` (1) → `test/emails/`
3. `spec/mailers/` (6) → `test/mailers/`
4. `spec/loaders/` (8) → `test/loaders/`
5. `spec/jobs/` (23) → `test/jobs/`
6. `spec/models/` (11) → `test/models/`
7. `spec/requests/omniauth_callbacks_spec.rb` (1) → `test/integration/omniauth_callbacks_test.rb`

Per file:

- `describe X` → `class XTest < ActiveSupport::TestCase` (or `ActionMailer::TestCase` / `ActiveJob::TestCase` etc.).
- `context "when …" do … end` → either separate `test` methods with descriptive names, or `class WhenFooTest < XTest` nested classes when shared setup is heavy.
- `let(:foo) { … }` → `setup do @foo = … end` (memoization is per-test, matches `let` semantics).
- `before { … }` → `setup do … end`.
- `expect(x).to eq(y)` → `assert_equal y, x`. Use a translation table (below) for common matchers.
- `it { is_expected.to validate_presence_of(:name) }` → `should validate_presence_of(:name)` (shoulda-matchers Minitest syntax).

After each subfolder is done:

```bash
bin/rails test test/<folder>
bundle exec standardrb --fix test/<folder>
bundle exec rspec   # ensure remaining specs still green
```

Commit per subfolder. Update CI matrix only when an entire folder is gone from `spec/`.

### Matcher translation table

| RSpec                       | Minitest                          |
| --------------------------- | --------------------------------- |
| `expect(x).to eq(y)`        | `assert_equal y, x`               |
| `expect(x).to be y`         | `assert_same y, x`                |
| `expect(x).to be_nil`       | `assert_nil x`                    |
| `expect(x).to be_truthy`    | `assert x`                        |
| `expect(x).to be_falsey`    | `refute x`                        |
| `expect(x).to include(y)`   | `assert_includes x, y`            |
| `expect(x).to match(/r/)`   | `assert_match(/r/, x)`            |
| `expect { … }.to raise_error(E)` | `assert_raises(E) { … }`     |
| `expect { … }.to change { x }.by(1)` | `assert_difference -> { x }, 1 do … end` |
| `allow(X).to receive(:m).and_return(v)` | `X.stubs(:m).returns(v)` (mocha) OR `Minitest::Mock` |

If mock usage is heavy, decide per-file: prefer `Minitest::Mock` first, fall back to adding `mocha` if needed.

## Phase 2 — Request specs (~349 files)

Convert resource-by-resource. A "resource" = one immediate subfolder of `spec/requests/api/v1/` (or sibling paths). Largest single resource is ~30 files; most are 1–5.

Per resource:

1. Move `spec/requests/<resource>/*_spec.rb` → `test/integration/<resource>/*_test.rb`.
2. Rewrite using `openapi-ruby` Style 2:
   - `RSpec.describe "..." type: :openapi` → `class FooTest < ActionDispatch::IntegrationTest; include OpenapiRuby::Adapters::Minitest::DSL`.
   - `openapi_schema :"public/v1/schema"` at top.
   - `path "..."` → `api_path "..."` (same nested block content for operation/response declarations — `let` blocks inside must move out).
   - Each `response(...) { run_test! }` becomes a separate `test "..."` block calling `assert_api_response :method, status, params:, body:, path_params:, headers:`.
   - `let(:user)` etc. → `setup do @user = create(:user); sign_in @user end`.
3. **Verify schema is unchanged:**
   ```bash
   # Before:
   cp swagger/schema.yaml /tmp/schema-before.yaml
   ./bin/generate-schema
   diff /tmp/schema-before.yaml swagger/schema.yaml
   ```
   Empty diff = safe. Non-empty diff requires explanation in the commit.
4. Run the new tests + the rest of the suite:
   ```bash
   bin/rails test test/integration/<resource>
   bundle exec rspec spec/requests   # remaining
   bundle exec standardrb --fix test/integration/<resource>
   ```
5. Commit per resource. Group small resources into a single commit when sensible.

Order (suggested, smallest first to build confidence):

- `version`, `features`, `sc_data_version` (1 file each, ~20 LOC)
- `oauth/*` (~5 files)
- `short/*` (1 file)
- … and so on, ending with the heaviest resources (`hangar/*`, `fleets/*`, `admin/*`).

Use `git ls-files spec/requests/api/v1 | awk -F/ '{print $4}' | sort -u` to enumerate resources before starting.

## Phase 3 — Cleanup

Once `spec/` contains only `factories/`, `support/`, `fixtures/`, `playwright/`:

1. Move `spec/factories/` → `test/factories/`. Update `FactoryBot.definition_file_paths` in `test_helper.rb`.
2. Move `spec/fixtures/` → `test/fixtures/files/` (adjust spec file paths in code that references them).
3. Move `spec/support/` contents into `test/test_helper.rb` (or split into `test/support/*.rb` and require them).
4. Decide what to do with `spec/playwright/` — Playwright tests run via `pnpm test:e2e:run`, not Ruby; rename folder to `playwright/` or keep, but disconnect from "spec" terminology.
5. Remove from Gemfile: `rspec-rails`, `flatware-rspec`.
6. Delete: `.rspec`, `spec/spec_helper.rb`, `spec/rails_helper.rb`, `spec/openapi_helper.rb`.
7. CI: drop the `bundle exec rspec` step; the existing `bin/rails test` is now the only Ruby test runner.
8. Docs: update `AGENTS.md`, `README.md`, any cursor rules referencing RSpec — point to Minitest commands.

## Verification at every phase

After every commit:

```bash
bin/rails test                       # Minitest suite green
bundle exec rspec                    # RSpec suite green (until Phase 3)
./bin/generate-schema                # Schema generation succeeds
git diff --stat swagger/schema.yaml  # No unexplained schema drift
bundle exec standardrb --fix <changed_files>
```

Phase 2 schema verification is the most important guard — any byte-level drift in `swagger/schema.yaml` must be either zero or explainable (e.g. only the operation order changed because Minitest loads files in a different order — acceptable if response/request schemas are unchanged).

## Risks

- **Schema drift in Phase 2.** Mitigation: byte-diff per resource commit.
- **Hidden RSpec-only matchers.** Mitigation: translation table; spot-fix as we go.
- **`flatware-rspec` parallelism replaced with Rails parallel runner** — process-level forking, similar semantics, but each worker gets a separate DB connection (already true under flatware). Should be drop-in.
- **`openapi-ruby` Style 2 may behave subtly differently** than Style 1 for edge-case `let` overrides (e.g. nullifying `user` for 401 responses). Verify in the first 2-3 small resources before scaling.

## Out of scope

- Frontend tests (Vitest, Playwright) — unchanged.
- Test infrastructure changes (sidekiq fake mode, DB cleaning strategy, factories) — kept as-is.
- New test coverage — no new tests added during migration unless filling a gap exposed by the conversion.
