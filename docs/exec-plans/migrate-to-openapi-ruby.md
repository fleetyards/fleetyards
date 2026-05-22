# Migrate from rswag + committee + rswag-schema_components to openapi-ruby

## Context

FleetYards currently uses three gems for OpenAPI:
- **rswag** (rswag-api 2.17.0, rswag-specs 2.17.0) — test-driven spec generation
- **rswag-schema_components** (0.6.0) — reusable schema component system
- **committee** (5.6.2) — runtime request validation middleware

**openapi-ruby** (3.0.2) replaces all three with a single gem that provides the same DSL, component system, and middleware — plus OpenAPI 3.1 support, form data handling, eager $ref validation, and auto-injected 400 validation error responses.

### Gem API verification

All assumed APIs have been verified against the unpacked gem source (v3.0.2):
- `OpenapiRuby.configure` with `schemas`, `component_paths`, `component_scope_paths`, `camelize_keys`, `schema_output_format`, `schema_output_dir`, `request_validation`, `response_validation`, `strict_reference_validation`, `auto_validation_error_response`, `validation_error_schema`, `error_handler`
- `OpenapiRuby::Components::Base` — mixin with `schema()`, `schema_hidden()`, `component_type()`, `component_scopes()`, `shared_component`, `skip_key_transformation`, `permitted_params`, `to_openapi`
- `OpenapiRuby::Adapters::RSpec.install!` — registers DSL on `type: :openapi`, reads `metadata[:openapi_schema_name]`
- `OpenapiRuby::Engine` — serves schemas and optional Swagger UI, auto-inserts validation middleware
- `openapi_ruby:generate` rake task
- `OpenapiRuby::Middleware::ErrorHandler` — `invalid_request(errors)`, `not_found(path)`, `invalid_response(errors)`
- Per-schema `openapi_version` option (can keep `"3.0.3"` to defer nullable migration)

### Current state inventory

| What | Count | Location |
|---|---|---|
| Component files with `include Rswag::SchemaComponents::Component` | 250 | `app/api_components/` |
| Files with `nullable` usage | 34 (178 occurrences) | `app/api_components/` |
| Request spec files | ~295 | `spec/requests/` |
| Schema configs | 3 | v1, admin/v1, oauth/v1 |
| Rswag engine mount in routes | **0** (not mounted) | — |
| CI references to rswag rake tasks | **0** | `.github/workflows/` |

---

## Phase 1: Gem Swap + Configuration

### 1.1 Update Gemfile
```ruby
# Remove:
gem "rswag-api"
gem "rswag-specs", require: false
gem "rswag-schema_components"
gem "committee"

# Add:
gem "openapi-ruby"
```

Run `bundle install`.

### 1.2 Create initializer

Create `config/initializers/openapi_ruby.rb`:

```ruby
OpenapiRuby.configure do |config|
  config.schemas = {
    "v1/schema" => {
      openapi_version: "3.0.3",
      info: {
        title: "FleetYards.net API",
        version: "v1",
        license: {
          name: "GNU General Public License v3.0",
          url: "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        },
        "x-logo": {
          url: "https://fleetyards.net/docs/logo.png",
          altText: "FleetYards.net logo"
        }
      },
      servers: [
        { url: API_ENDPOINT, description: "Dev Server" },
        { url: "https://api.fleetyards.net/v1", description: "Production Server" },
        { url: "https://api.fleetyards.dev/v1", description: "Staging Server" }
      ],
      security: [],
      component_scope: :v1,
      prefix: URI.parse(API_ENDPOINT).path
    },
    "admin/v1/schema" => {
      openapi_version: "3.0.3",
      info: {
        title: "FleetYards.net Command API",
        version: "v1",
        license: {
          name: "GNU General Public License v3.0",
          url: "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        },
        "x-logo": {
          url: "https://fleetyards.net/docs/logo.png",
          altText: "FleetYards.net logo"
        }
      },
      servers: [
        { url: ADMIN_API_ENDPOINT, description: "Dev Server" },
        { url: "http://admin.fleetyards.test/api/v1", description: "Production Server" },
        { url: "https://admin.fleetyards.dev/api/v1", description: "Staging Server" }
      ],
      security: [
        SessionCookie: []
      ],
      component_scope: :admin,
      prefix: URI.parse(ADMIN_API_ENDPOINT).path
    },
    "oauth/v1/schema" => {
      openapi_version: "3.0.3",
      info: {
        title: "FleetYards.net OAuth API",
        version: "v1",
        license: {
          name: "GNU General Public License v3.0",
          url: "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        }
      },
      servers: [
        { url: OAUTH_ENDPOINT, description: "Dev Server" },
        { url: "https://fleetyards.net/oauth", description: "Production Server" },
        { url: "https://fleetyards.dev/oauth", description: "Staging Server" }
      ],
      security: [],
      component_scope: :oauth
    }
  }

  config.component_paths = ["app/api_components"]
  config.component_scope_paths = {
    "v1"        => :v1,
    "admin/v1"  => :admin,
    "oauth/v1"  => :oauth,
    "shared/v1" => :shared
  }

  config.camelize_keys = false  # fleetyards already uses camelCase in component schemas
  config.schema_output_format = :yaml
  config.schema_output_dir = "swagger"

  config.request_validation = ENV.fetch("SKIP_COMMITTEE", false) ? :disabled : :enabled
  config.response_validation = :disabled
  config.strict_reference_validation = true

  config.auto_validation_error_response = true
  config.validation_error_schema = {
    "type" => "object",
    "properties" => {
      "code" => { "type" => "string" },
      "message" => { "type" => "string" }
    },
    "required" => %w[code message]
  }

  # Match legacy ApiValidationError format: { code: id, message: message }
  config.error_handler = Class.new(OpenapiRuby::Middleware::ErrorHandler) {
    def invalid_request(errors)
      body = { code: "validation_error", message: errors.first }.to_json
      [400, { "content-type" => "application/json" }, [body]]
    end
  }.new
end
```

**Decision: Keep OpenAPI 3.0.3 initially** — uses per-schema `openapi_version: "3.0.3"` to avoid a mass `nullable` migration. The bump to 3.1 can be done as a separate follow-up.

### 1.3 Delete old config files
- `config/initializers/rswag_api.rb`
- `config/initializers/rswag_monkey_patch.rb` — the form data monkey patch is replaced by openapi-ruby's built-in form data handling
- `config/initializers/03_committee.rb`
- `lib/api_validation_error.rb`

### 1.4 Update or remove `config/app/api_schema.yml`

Currently contains:
```yaml
shared:
  folder: swagger
  oas_version: 3.0.3
```

This is referenced as `Rails.configuration.api_schema.oas_version` and `Rails.configuration.api_schema.folder` in the old swagger_helper. After migration these values live in the openapi-ruby config, so either:
- Remove the file entirely if no other code references it
- Or keep it if other parts of the app use `Rails.configuration.api_schema.folder`

Search for remaining references before deleting:
```bash
grep -rn "api_schema" app/ config/ lib/ spec/
```

---

## Phase 2: Migrate Components (250 files)

### 2.1 Replace mixin in all component files

Find-and-replace across `app/api_components/`:
```
# Before:
include Rswag::SchemaComponents::Component

# After:
include OpenapiRuby::Components::Base
```

250 files need this change.

### 2.2 Verify `to_schema` vs `to_openapi`

The custom `SchemaConcern` defines `to_schema` as the public method. `OpenapiRuby::Components::Base` uses `to_openapi` instead. Check if any code calls `to_schema` directly:
```bash
grep -rn "\.to_schema" app/ lib/ spec/
```

The `ComponentsLoader` calls `component.to_schema` — but since we're deleting that file (Phase 2.3), this is fine. If any other code calls `to_schema`, it needs to change to `to_openapi`.

### 2.3 Delete custom component infrastructure
- `app/api_components/components_loader.rb` — replaced by built-in Loader
- `app/api_components/concerns/schema_concern.rb` — replaced by Components::Base

### 2.4 Migrate ParamsHelper

`ParamsHelper` (`app/api_components/params_helper.rb`) is **actively used** in:
- `app/controllers/concerns/hangar_filters_concern.rb:5` — `ParamsHelper.new("v1/schema.yaml").to_params("HangarQuery")`

It references `Rswag::Api.config.openapi_root` to load the YAML schema. Two options:

**Option A — Migrate to openapi-ruby's `permitted_params`**: The `OpenapiRuby::Components::Base` mixin provides `permitted_params` which derives Rails strong params from the schema definition. Rewrite the concern to use this:
```ruby
# Before:
@vehicle_query_params ||= params.permit(q: ParamsHelper.new("v1/schema.yaml").to_params("HangarQuery")).fetch(:q, {})

# After:
@vehicle_query_params ||= params.permit(q: V1::Schemas::Queries::HangarQuery.permitted_params).fetch(:q, {})
```

**Option B — Keep ParamsHelper, update the config reference**:
```ruby
# Before:
YAML.load_file(Rails.root.join(Rswag::Api.config.openapi_root, schema_path))
# After:
YAML.load_file(Rails.root.join(OpenapiRuby.config.schema_output_dir, schema_path))
```

**Recommendation**: Option A — it's cleaner and removes the YAML parsing indirection.

### 2.5 Add `component_type` declarations

Components in non-default types need explicit `component_type` calls. In the old setup, `ComponentsLoader` inferred type from directory name. In openapi-ruby, `Components::Base` defaults to `:schemas`.

Files needing changes:
- `shared/v1/parameters/page_parameter.rb` — add `component_type :parameters`
- `shared/v1/parameters/sorting_parameter.rb` — add `component_type :parameters`
- `shared/v1/security_schemes/oauth2.rb` — add `component_type :security_schemes`
- `shared/v1/security_schemes/bearer_auth.rb` — add `component_type :security_schemes`
- `shared/v1/security_schemes/open_id.rb` — add `component_type :security_schemes`
- `shared/v1/security_schemes/session_cookie.rb` — add `component_type :security_schemes`
- `oauth/v1/security_schemes/session_cookie.rb` — add `component_type :security_schemes`

### 2.6 Nullable syntax (deferred)

Since we're keeping `openapi_version: "3.0.3"` (Phase 1.2), the `nullable: true` syntax remains valid. **No changes needed now.** The 178 occurrences across 34 files can be converted when upgrading to 3.1 later.

---

## Phase 3: Migrate Request Specs (~295 files)

### 3.1 Replace swagger_helper with openapi_helper

Create `spec/openapi_helper.rb`:
```ruby
require "rails_helper"
require "openapi_ruby/rspec"
```

Note: `require "openapi_ruby/rspec"` auto-calls `OpenapiRuby::Adapters::RSpec.install!` — no explicit call needed.

### 3.2 Update spec files

**In every request spec file**, change:
```ruby
# Before:
require "swagger_helper"
RSpec.describe "...", type: :request, swagger_doc: "v1/schema.yaml" do

# After:
require "openapi_helper"
RSpec.describe "...", type: :openapi, openapi_schema_name: :"v1/schema" do
```

Per-spec metadata replacements:
- `type: :request, swagger_doc: "v1/schema.yaml"` → `type: :openapi, openapi_schema_name: :"v1/schema"`
- `type: :request, swagger_doc: "admin/v1/schema.yaml"` → `type: :openapi, openapi_schema_name: :"admin/v1/schema"`
- `type: :request, swagger_doc: "oauth/v1/schema.yaml"` → `type: :openapi, openapi_schema_name: :"oauth/v1/schema"`

Note: schema names drop the `.yaml` extension — they reference the config keys, not file paths.

### 3.3 DSL compatibility

The DSL is identical — no changes needed for:
- `path "/endpoint" do ... end`
- `get/post/put/patch/delete("summary") do ... end`
- `operationId`, `tags`, `produces`, `consumes`
- `parameter name:, in:, schema:, ...`
- `request_body required:, content: { ... }`
- `response(200, "description") do ... end`
- `schema "$ref": "#/components/schemas/..."`
- `run_test!`
- `let(:param)` blocks

### 3.4 Update Rakefile

```ruby
# Before (line 8):
require "rswag/specs"

# After:
require "openapi_ruby"
```

The rake task changes from `rswag:specs:swaggerize` to `openapi_ruby:generate`.

---

## Phase 4: Verify Middleware

### 4.1 Error format compatibility

The old `ApiValidationError` returned `{ code: id, message: message }`. The custom error handler in the initializer (Phase 1.2) preserves this format.

Verify at runtime that the error response matches by hitting an endpoint with invalid params and comparing the response body format.

### 4.2 Verify prefix matching

The committee setup uses `prefix: URI.parse(API_ENDPOINT).path`. The same pattern is used in the openapi-ruby config. Verify the prefixes match by comparing:
```ruby
URI.parse(API_ENDPOINT).path        # e.g., "/v1"
URI.parse(ADMIN_API_ENDPOINT).path  # e.g., "/api/v1"
```

### 4.3 No route mount needed

The rswag engine is **not currently mounted in routes** — schemas are served statically or through a different mechanism. When adding `OpenapiRuby::Engine`, decide whether to mount it:
- If you want the engine to serve schemas at runtime: `mount OpenapiRuby::Engine => "/api-docs"`
- If schemas are served as static YAML files (current behavior): no mount needed
- The engine also provides optional Swagger UI at `/api-docs/ui` (`config.ui_enabled = true`)

---

## Phase 5: Generate + Compare

### 5.1 Back up old specs

```bash
cp swagger/v1/schema.yaml swagger/v1/schema.yaml.bak
cp swagger/admin/v1/schema.yaml swagger/admin/v1/schema.yaml.bak
cp swagger/oauth/v1/schema.yaml swagger/oauth/v1/schema.yaml.bak
```

### 5.2 Generate new specs

```bash
bundle exec rake openapi_ruby:generate
```

### 5.3 Diff against old specs

```bash
diff swagger/v1/schema.yaml swagger/v1/schema.yaml.bak
diff swagger/admin/v1/schema.yaml swagger/admin/v1/schema.yaml.bak
diff swagger/oauth/v1/schema.yaml swagger/oauth/v1/schema.yaml.bak
```

Expected differences (with 3.0.3 kept):
- `openapi: "3.0.3"` stays the same
- `nullable: true` stays the same (no conversion needed)
- Possible new `components/responses/ValidationError` section (from `auto_validation_error_response`)
- 400 responses may be auto-injected on all operations
- Possible alphabetical re-sorting of paths, components, and tags
- `title` field auto-added to schema components

### 5.4 Run full test suite

```bash
bundle exec rspec spec/requests/
```

All ~295 request specs should pass. Most likely failure causes:
- Missing `component_type :parameters` on parameter components
- Schema name metadata mismatch (`.yaml` left in name)
- `to_schema` called somewhere instead of `to_openapi`

---

## Phase 6: Cleanup

### 6.1 Delete old files
- `spec/swagger_helper.rb`
- `config/initializers/rswag_api.rb`
- `config/initializers/rswag_monkey_patch.rb`
- `config/initializers/03_committee.rb`
- `lib/api_validation_error.rb`
- `app/api_components/components_loader.rb`
- `app/api_components/concerns/schema_concern.rb`
- `app/api_components/params_helper.rb` (if migrated to `permitted_params` in Phase 2.4)

### 6.2 CI — no changes needed

No CI workflows reference `rswag:specs:swaggerize` or rswag-specific commands. The `api-schema-breaking.job.yml` workflow only diffs the generated YAML files — it will work unchanged with the new generator.

### 6.3 Optional: Update `config/app/api_schema.yml`

Remove or update once confirmed no other code depends on `Rails.configuration.api_schema`.

---

## Future follow-up: OpenAPI 3.1 upgrade

After the migration is stable, upgrade to OpenAPI 3.1 in a separate PR:
1. Change `openapi_version: "3.0.3"` to `"3.1.0"` (or remove — 3.1 is the default)
2. Convert `nullable: true` → `type: [:type, :null]` (34 files, 178 occurrences)
3. Regenerate specs and run the breaking-change diff workflow

---

## Migration Checklist

### Phase 1: Gem Swap
- [ ] Update Gemfile: remove rswag-api, rswag-specs, rswag-schema_components, committee; add openapi-ruby
- [ ] `bundle install`
- [ ] Create `config/initializers/openapi_ruby.rb` with full config (all servers, license, security, error handler)
- [ ] Delete `config/initializers/rswag_api.rb`
- [ ] Delete `config/initializers/rswag_monkey_patch.rb`
- [ ] Delete `config/initializers/03_committee.rb`
- [ ] Delete `lib/api_validation_error.rb`
- [ ] Audit `config/app/api_schema.yml` for remaining references

### Phase 2: Components (250 files)
- [ ] Find-and-replace `include Rswag::SchemaComponents::Component` → `include OpenapiRuby::Components::Base` (250 files)
- [ ] Check for `to_schema` calls outside deleted files — change to `to_openapi`
- [ ] Delete `app/api_components/components_loader.rb`
- [ ] Delete `app/api_components/concerns/schema_concern.rb`
- [ ] Migrate `ParamsHelper` in `hangar_filters_concern.rb` to use `permitted_params`
- [ ] Delete `app/api_components/params_helper.rb`
- [ ] Add `component_type :parameters` to 2 parameter components
- [ ] Add `component_type :security_schemes` to 5 security scheme components

### Phase 3: Request Specs (~295 files)
- [ ] Create `spec/openapi_helper.rb`
- [ ] Find-and-replace `require "swagger_helper"` → `require "openapi_helper"` (~295 files)
- [ ] Find-and-replace `type: :request, swagger_doc: "v1/schema.yaml"` → `type: :openapi, openapi_schema_name: :"v1/schema"`
- [ ] Find-and-replace `type: :request, swagger_doc: "admin/v1/schema.yaml"` → `type: :openapi, openapi_schema_name: :"admin/v1/schema"`
- [ ] Find-and-replace `type: :request, swagger_doc: "oauth/v1/schema.yaml"` → `type: :openapi, openapi_schema_name: :"oauth/v1/schema"`
- [ ] Update Rakefile: `require "rswag/specs"` → `require "openapi_ruby"`

### Phase 4: Verify
- [ ] Back up old schema YAML files
- [ ] Run `bundle exec rake openapi_ruby:generate`
- [ ] Diff generated schemas against backups
- [ ] Run `bundle exec rspec spec/requests/`
- [ ] Verify error format with a validation-failing request

### Phase 5: Cleanup
- [ ] Delete `spec/swagger_helper.rb`
- [ ] Decide on engine mount in routes (optional)
- [ ] Remove schema YAML backups
