# Migrate from rswag + committee + rswag-schema_components to openapi-ruby

## Context

FleetYards currently uses three gems for OpenAPI:
- **rswag** (rswag-api 2.17.0, rswag-specs 2.17.0) — test-driven spec generation
- **rswag-schema_components** (0.6.0) — reusable schema component system
- **committee** (5.6.2) — runtime request validation middleware

**openapi-ruby** replaces all three with a single gem that provides the same DSL, component system, and middleware — plus OpenAPI 3.1 support, form data handling, eager $ref validation, and auto-injected 400 validation error responses.

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
      info: { title: "FleetYards.net API", version: "v1" },
      servers: [
        { url: API_ENDPOINT, description: "Dev" },
        # add staging/production as needed
      ],
      component_scope: :v1,
      prefix: URI.parse(API_ENDPOINT).path
    },
    "admin/v1/schema" => {
      info: { title: "FleetYards.net Admin/CMD API", version: "v1" },
      servers: [
        { url: ADMIN_API_ENDPOINT, description: "Dev" },
      ],
      component_scope: :admin,
      prefix: URI.parse(ADMIN_API_ENDPOINT).path
    },
    "oauth/v1/schema" => {
      info: { title: "FleetYards.net OAuth", version: "v1" },
      servers: [
        { url: OAUTH_ENDPOINT, description: "Dev" },
      ],
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
end
```

### 1.3 Delete old config files
- `config/initializers/rswag_api.rb`
- `config/initializers/rswag_monkey_patch.rb`
- `config/initializers/03_committee.rb`
- `lib/api_validation_error.rb`

---

## Phase 2: Migrate Components (~277 files)

### 2.1 Replace mixin in all component files

Find-and-replace across `app/api_components/`:
```
# Before:
include Rswag::SchemaComponents::Component

# After:
include OpenapiRuby::Components::Base
```

This is a single `sed` or IDE find-and-replace. The `schema({...})`, `schema_hidden`, and inheritance patterns are identical.

### 2.2 Delete custom component infrastructure
- `app/api_components/components_loader.rb` — replaced by built-in Loader
- `app/api_components/concerns/schema_concern.rb` — replaced by Components::Base
- `app/api_components/params_helper.rb` — check if still needed, may be replaced by `permitted_params`

### 2.3 Verify component_type declarations

Components that use non-default types need `component_type` calls. Check:
- `shared/v1/parameters/*.rb` — should have `component_type :parameters`
- `shared/v1/security_schemes/*.rb` — should have `component_type :security_schemes`

In rswag-schema_components, the component type was inferred from the directory name by the custom loader. In openapi-ruby, it defaults to `:schemas` — so parameter and security_scheme components need explicit `component_type` declarations.

### 2.4 Audit for nullable syntax (OpenAPI 3.0 → 3.1)

Search for `nullable: true` in all component files:
```bash
grep -rn "nullable" app/api_components/
```

Convert any matches:
```ruby
# Before (3.0):
name: { type: :string, nullable: true }

# After (3.1):
name: { type: [:string, :null] }
```

---

## Phase 3: Migrate Request Specs (~295 files)

### 3.1 Replace swagger_helper with openapi_helper

Create `spec/openapi_helper.rb`:
```ruby
require "rails_helper"
require "openapi_ruby/rspec"

OpenapiRuby::Adapters::RSpec.install!
```

### 3.2 Update spec files

**In every request spec file**, change:
```ruby
# Before:
require "swagger_helper"
RSpec.describe "...", type: :request, swagger_doc: "v1/schema.yaml" do

# After:
require "openapi_helper"
RSpec.describe "...", type: :openapi do
```

The schema assignment (`swagger_doc: "v1/schema.yaml"`) maps to setting the schema name in the describe block metadata. Two approaches:

**Option A — Global default**: If most specs are for the same schema, set a default and override where needed:
```ruby
# In openapi_helper.rb:
RSpec.configure do |config|
  config.add_setting :default_openapi_schema, default: :"v1/schema"
end
```

**Option B — Per-spec metadata**: Add `openapi_schema_name:` to each describe block:
```ruby
RSpec.describe "...", type: :openapi, openapi_schema_name: "v1/schema" do
```

Recommendation: Option B is more explicit. Use find-and-replace:
- `swagger_doc: "v1/schema.yaml"` → `openapi_schema_name: :"v1/schema"`
- `swagger_doc: "admin/v1/schema.yaml"` → `openapi_schema_name: :"admin/v1/schema"`
- `swagger_doc: "oauth/v1/schema.yaml"` → `openapi_schema_name: :"oauth/v1/schema"`

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
# Before:
require "rswag/specs"

# After:
require "openapi_ruby"
```

The rake task changes from `rswag:specs:swaggerize` to `openapi_ruby:generate`.

---

## Phase 4: Verify Middleware

### 4.1 Error format compatibility

The old `ApiValidationError` returned `{ code: id, message: message }`. Configure the same in openapi-ruby:

The `validation_error_schema` in the config (Phase 1.2) already matches this format. The actual error rendering is handled by the default `ErrorHandler` which returns `{ error: "...", details: [...] }`.

If the exact `{ code, message }` format is required for API consumers, create a custom error handler:
```ruby
config.error_handler = Class.new(OpenapiRuby::Middleware::ErrorHandler) {
  def invalid_request(errors)
    body = { code: "validation_error", message: errors.first }.to_json
    [400, { "content-type" => "application/json" }, [body]]
  end
}.new
```

### 4.2 Verify prefix matching

The committee setup uses `prefix: URI.parse(API_ENDPOINT).path`. The same pattern is used in the openapi-ruby config. Verify the prefixes match by comparing:
```ruby
URI.parse(API_ENDPOINT).path        # e.g., "/v1"
URI.parse(ADMIN_API_ENDPOINT).path  # e.g., "/api/v1"
```

---

## Phase 5: Generate + Compare

### 5.1 Generate new specs

```bash
bundle exec rake openapi_ruby:generate
```

### 5.2 Diff against old specs

```bash
diff swagger/v1/schema.yaml swagger/v1/schema.yaml.bak
diff swagger/admin/v1/schema.yaml swagger/admin/v1/schema.yaml.bak
diff swagger/oauth/v1/schema.yaml swagger/oauth/v1/schema.yaml.bak
```

Expected differences:
- `openapi: "3.1.0"` instead of `"3.0.3"`
- `nullable: true` replaced with `type: [string, null]` (from Phase 2.4)
- New `components/responses/ValidationError` section
- 400 responses auto-injected on all operations
- Alphabetical sorting of paths, components, and tags
- `title` field auto-added to schema components

### 5.3 Run full test suite

```bash
bundle exec rspec spec/requests/
```

All 295 request specs should pass. Fix any failures — most likely causes:
- Missing `component_type :parameters` on parameter components
- `nullable` syntax not converted
- Schema name metadata mismatch

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

### 6.2 Update routes

```ruby
# Before (if rswag engine was mounted):
mount Rswag::Api::Engine => "/api-docs"

# After:
mount OpenapiRuby::Engine => "/api-docs"
```

### 6.3 Update CI

Replace any CI steps that reference:
- `rswag:specs:swaggerize` → `openapi_ruby:generate`
- `rswag` gem references in CI config

---

## Migration Checklist

- [ ] Update Gemfile and bundle install
- [ ] Create `config/initializers/openapi_ruby.rb`
- [ ] Delete old initializers (rswag_api, rswag_monkey_patch, 03_committee)
- [ ] Delete `lib/api_validation_error.rb`
- [ ] Find-and-replace `Rswag::SchemaComponents::Component` → `OpenapiRuby::Components::Base` (~277 files)
- [ ] Add `component_type` declarations to parameter/security_scheme components
- [ ] Delete `components_loader.rb` and `schema_concern.rb`
- [ ] Audit and convert `nullable: true` → `type: [:type, :null]`
- [ ] Create `spec/openapi_helper.rb`
- [ ] Find-and-replace `require "swagger_helper"` → `require "openapi_helper"` (~295 files)
- [ ] Find-and-replace `type: :request, swagger_doc:` → `type: :openapi, openapi_schema_name:` (~295 files)
- [ ] Update Rakefile
- [ ] Update routes (engine mount)
- [ ] Configure custom error handler if needed
- [ ] Generate specs and diff against old output
- [ ] Run full request spec suite
- [ ] Update CI configuration
- [ ] Delete `spec/swagger_helper.rb`
