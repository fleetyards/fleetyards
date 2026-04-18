# Migrate from rswag to openapi-ruby

## Goal

Replace `rswag-api`, `rswag-specs`, `rswag-schema_components`, and `committee` with the single `openapi-ruby` gem. This unifies spec generation, schema components, and runtime validation under one library.

## Current State

- **Gems**: `rswag-api` 2.17.0, `rswag-specs` 2.17.0, `rswag-schema_components` 0.6.0, `committee` (unused)
- **Spec files**: 299 request specs in `spec/requests/`
- **Component files**: 279 Ruby classes in `app/api_components/`
- **Schema outputs**: 3 YAML schemas (v1, admin/v1, oauth/v1) in `swagger/`
- **OpenAPI version**: 3.0.3 (configured in `config/app/api_schema.yml`)
- **Test type**: `type: :request` with `swagger_doc:` metadata
- **Helper**: `spec/swagger_helper.rb` (requires `rswag/specs`)
- **Parameter passing**: body params via `parameter name: :input, in: :body` + `let(:input)`, query/path params via `let(:paramName)`, auth via `let(:Authorization)` or session cookies
- **Shared examples**: `admin_auth` and `oauth_auth` for auth error responses
- **Monkey patch**: `config/initializers/rswag_monkey_patch.rb` (form payload handling)
- **ParamsHelper**: `app/api_components/params_helper.rb` — derives strong params from YAML schema, uses `Rswag::Api.config.openapi_root`
- **Schema controllers**: 3 controllers serving YAML files (Api::SchemaController, Admin::Api::SchemaController, Oauth::SchemaController)

## Key Differences (rswag vs openapi-ruby)

| Aspect | rswag | openapi-ruby |
|--------|-------|-------------|
| Gem(s) | rswag-api + rswag-specs + rswag-schema_components | openapi-ruby (single gem) |
| RSpec type | `type: :request` | `type: :openapi` |
| Schema selector | `swagger_doc: "v1/schema.yaml"` | Schema key in config + `openapi_schema` |
| Require | `require "swagger_helper"` | `require "openapi_helper"` |
| Component include | `Rswag::SchemaComponents::Component` | `OpenapiRuby::Components::Base` |
| Config | `swagger_helper.rb` + `rswag_api.rb` initializer | `config/initializers/openapi_ruby.rb` |
| Body params | `parameter name: :input, in: :body` + `let(:input)` | `request_body` DSL + `let(:request_body)` |
| Query/path params | `let(:paramName)` (resolved via `#send`) | `let(:paramName)` (resolved via `resolve_let`) — **compatible** |
| Auth params | `let(:Authorization)` (resolved via `#send`) | Resolved via security scheme config — **compatible** |
| Schema generation | `rswag:specs:swaggerize` rake task | `openapi_ruby:generate` rake task + auto after suite |
| Runtime validation | committee (separate) | Built-in middleware |
| Strong params | `ParamsHelper` (custom, reads YAML) | `OpenapiRuby::ControllerHelpers` + `permitted_params` |
| Swagger UI | Not used | Built-in engine (optional) |
| Schema serving | Custom controllers | Built-in engine routes |
| Scoping | `Rswag::SchemaComponents::Loader.new("v1")` | `component_scope_paths` config |
| Key transformation | Handled in component classes | `config.camelize_keys = true` global setting |
| Hidden responses | Not supported | `response 200, "desc", hidden: true` |

## Migration Plan

### Phase 1: Gem swap and configuration

1. **Update Gemfile**
   - Remove: `rswag-api`, `rswag-specs`, `rswag-schema_components`, `committee`
   - Add: `gem "openapi-ruby"`
   - Run `bundle install`

2. **Create initializer** `config/initializers/openapi_ruby.rb`:
   ```ruby
   OpenapiRuby.configure do |config|
     config.schemas = {
       "v1/schema.yaml": {
         openapi_version: "3.0.3",
         info: {
           title: "FleetYards.net API",
           version: "v1",
           license: { name: "GNU General Public License v3.0", url: "..." },
           "x-logo": { url: "...", altText: "FleetYards.net logo" }
         },
         servers: [
           { url: API_ENDPOINT, description: "Dev Server" },
           { url: "https://api.fleetyards.net/v1", description: "Production Server" },
           { url: "https://api.fleetyards.dev/v1", description: "Staging Server" }
         ],
         security: [],
         component_scope: :v1
       },
       "admin/v1/schema.yaml": {
         openapi_version: "3.0.3",
         info: { title: "FleetYards.net Command API", version: "v1", ... },
         servers: [...],
         security: [{ SessionCookie: [] }],
         component_scope: :admin_v1
       },
       "oauth/v1/schema.yaml": {
         openapi_version: "3.0.3",
         info: { title: "FleetYards.net OAuth API", version: "v1", ... },
         servers: [...],
         security: [],
         component_scope: :oauth_v1
       }
     }

     config.component_paths = [Rails.root.join("app/api_components").to_s]
     config.component_scope_paths = {
       "v1" => :v1,
       "admin/v1" => :admin_v1,
       "oauth/v1" => :oauth_v1,
       "shared/v1" => :shared
     }
     config.camelize_keys = true
     config.schema_output_dir = Rails.root.join("swagger").to_s
     config.schema_output_format = :yaml
     config.validate_responses_in_tests = true
     config.request_validation = :disabled
     config.response_validation = :disabled
     config.ui_enabled = false
   end
   ```

3. **Delete old config files**:
   - `config/initializers/rswag_api.rb`
   - `config/initializers/rswag_monkey_patch.rb`
   - `config/app/api_schema.yml` (if no longer referenced elsewhere)

4. **Mount engine** in `config/routes.rb`:
   ```ruby
   mount OpenapiRuby::Engine => "/api-docs"
   ```

5. **Remove old schema controller routes** and controllers:
   - `app/controllers/api/schema_controller.rb`
   - `app/controllers/admin/api/schema_controller.rb`
   - `app/controllers/oauth/schema_controller.rb`
   - Corresponding route entries

### Phase 2: Migrate schema components (279 files)

This is a bulk find-and-replace. Each component needs:

**Before:**
```ruby
module V1
  module Schemas
    module Fleets
      class Fleet
        include Rswag::SchemaComponents::Component

        schema({ ... })
      end
    end
  end
end
```

**After:**
```ruby
module V1
  module Schemas
    module Fleets
      class Fleet
        include OpenapiRuby::Components::Base

        schema({ ... })
      end
    end
  end
end
```

Changes:
- Replace `include Rswag::SchemaComponents::Component` with `include OpenapiRuby::Components::Base` (all 279 files)
- SecurityScheme components need `component_type :securitySchemes` added (check if rswag-schema_components auto-detected this from the namespace)
- Parameter components need `component_type :parameters`
- The `schema({...})` call is compatible — same API

**Automation**: single `sed` or search-and-replace across all files:
```
Rswag::SchemaComponents::Component -> OpenapiRuby::Components::Base
```

### Phase 3: Migrate test helper

**Replace `spec/swagger_helper.rb`** with `spec/openapi_helper.rb`:

```ruby
# frozen_string_literal: true

require "rails_helper"
require "openapi_ruby/rspec"
```

That's it — the configuration is now in the initializer, not the helper.

### Phase 4: Migrate spec files (299 files)

Each spec needs these changes:

#### 4a. Require and metadata (all 299 files)

**Before:**
```ruby
require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
```

**After:**
```ruby
require "openapi_helper"

RSpec.describe "api/v1/models", type: :openapi do
```

Notes:
- `type: :request` becomes `type: :openapi` (openapi-ruby auto-includes `RSpec::Rails::RequestExampleGroup`)
- `swagger_doc: "v1/schema.yaml"` is removed — the schema is resolved from the server URL base path matching the `path` template, OR explicitly via `openapi_schema :"v1/schema.yaml"` at the top of the describe block
- Since we have 3 schemas with different base paths, the specs should work without explicit schema selection IF the base paths are unique. However, the admin specs use relative paths like `/fleets` (not `/admin/api/v1/fleets`), so they'll need explicit schema assignment.

**For public API specs** (165 files): Schema resolves from server URL, no explicit assignment needed if base path is unique.

**For admin API specs** (132 files): Add `openapi_schema :"admin/v1/schema.yaml"` inside the describe block (or figure out if path prefix is sufficient).

**For OAuth specs** (1 file): Add `openapi_schema :"oauth/v1/schema.yaml"`.

**Simpler approach**: Always set `openapi_schema` explicitly in every spec to be safe — it's a one-line addition per file and avoids any ambiguity.

#### 4b. Body parameter conversion (~74 files)

**Before:**
```ruby
parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetInput"}, required: true

# value provided via:
let(:input) do
  { name: "Test Fleet", fid: "test-fleet" }
end
```

**After:**
```ruby
request_body required: true, content: {
  "application/json" => {
    schema: { "$ref" => "#/components/schemas/FleetInput" }
  }
}

# value provided via:
let(:request_body) do
  { name: "Test Fleet", fid: "test-fleet" }
end
```

Notes:
- Every `parameter name: :input, in: :body, schema: ...` becomes a `request_body` DSL call
- Every `let(:input) { ... }` becomes `let(:request_body) { ... }`
- The `consumes "application/json"` line can stay (openapi-ruby supports it)
- If a spec overrides `let(:input)` in nested contexts, those all become `let(:request_body)`

#### 4c. Query and path parameters — mostly compatible

`let(:q)`, `let(:perPage)`, `let(:id)` etc. work as-is — openapi-ruby's `resolve_let` resolves them by name, same as rswag's `#send`.

The `parameter` DSL calls are compatible.

#### 4d. Auth parameters — mostly compatible

- `let(:Authorization)` works — openapi-ruby resolves security scheme params via `resolve_security_params` which looks up the scheme type and creates the right header/query param
- Session cookie auth (admin specs using `sign_in(user)`) works unchanged — it's Rails test infrastructure, not rswag-specific

#### 4e. run_test! block signature

**Before:**
```ruby
run_test! do |response|
  data = JSON.parse(response.body)
end
```

**After:**
```ruby
run_test! do
  data = JSON.parse(response.body)
end
```

The openapi-ruby `run_test!` block does NOT pass `response` as a block argument. Instead, `response` is available as a method (standard Rails test). This is a subtle but widespread change — need to remove the `|response|` parameter from all `run_test!` blocks.

**Count**: grep for `run_test! do |response|` to find affected files.

#### 4f. Shared examples

`admin_auth` and `oauth_auth` shared examples use the rswag DSL (`response`, `schema`, `run_test!`, `let`). These are all compatible with openapi-ruby since the DSL methods are the same. No changes needed.

#### 4g. Duplicate status code responses

Some specs have multiple `response(200, ...)` blocks with different test scenarios (e.g., `models/index_spec.rb`). In rswag, only the first one appears in the generated schema. openapi-ruby supports `hidden: true` for test-only responses:

**Before:**
```ruby
response(200, "successful") do
  schema "$ref": "#/components/schemas/Models"
  run_test! # first one generates schema
end

response(200, "successful") do
  schema "$ref": "#/components/schemas/Models"
  let(:q) { ... }
  run_test! # duplicate, doesn't appear in schema
end
```

**After:**
```ruby
response(200, "successful") do
  schema "$ref": "#/components/schemas/Models"
  run_test!
end

response(200, "successful", hidden: true) do
  schema "$ref": "#/components/schemas/Models"
  let(:q) { ... }
  run_test!
end
```

This is optional but cleaner — duplicate responses without `hidden: true` will keep the first one.

### Phase 5: Migrate ParamsHelper

**Before** (`app/api_components/params_helper.rb`):
- Reads YAML schema file using `Rswag::Api.config.openapi_root`
- Extracts properties and builds permit list

**After**: Replace with `OpenapiRuby::ControllerHelpers`:
```ruby
class Api::V1::UsersController < ActionController::API
  include OpenapiRuby::ControllerHelpers

  def create
    user = User.new(openapi_permit(Schemas::UserInput))
  end
end
```

Or keep `ParamsHelper` but update the schema root reference:
```ruby
def load_schema(schema_path)
  YAML.load_file(Rails.root.join(OpenapiRuby.configuration.schema_output_dir, schema_path))
end
```

Decision: check how many controllers use `ParamsHelper` and decide whether to migrate to `permitted_params` or just update the reference.

### Phase 6: Update CI/rake tasks

- Replace `rake rswag:specs:swaggerize` with `rake openapi_ruby:generate` in any CI scripts
- The `after(:suite)` hook auto-generates schemas when running the full test suite, so explicit rake calls may not be needed
- Update `oasdiff` CI step if it references the old task

### Phase 7: Cleanup

- Delete `spec/swagger_helper.rb` (replaced by `spec/openapi_helper.rb`)
- Delete `config/initializers/rswag_api.rb`
- Delete `config/initializers/rswag_monkey_patch.rb`
- Remove `rswag-api`, `rswag-specs`, `rswag-schema_components`, `committee` from Gemfile
- Delete schema controllers and routes (replaced by engine)
- Remove `require "rswag/specs"` from `Rakefile` if present
- Verify `swagger/` output matches before/after (diff the YAML files)

## Automation Strategy

Most changes are mechanical and can be scripted:

1. **Component include** (279 files): `sed` replace `Rswag::SchemaComponents::Component` -> `OpenapiRuby::Components::Base`
2. **Spec require** (299 files): `sed` replace `require "swagger_helper"` -> `require "openapi_helper"`
3. **Spec type** (299 files): regex replace `type: :request, swagger_doc: "..."` -> `type: :openapi`
4. **Body params** (~74 files): script to convert `parameter name: :input, in: :body` to `request_body` DSL and `let(:input)` to `let(:request_body)`
5. **run_test! blocks**: regex replace `run_test! do |response|` -> `run_test! do`

The body param conversion (item 4) is the trickiest to automate since the schema ref and `let(:input)` blocks vary.

## Risk Assessment

- **Low risk**: Component migration (pure include swap), require changes, type metadata
- **Medium risk**: Body param conversion (many files, varied patterns), ParamsHelper migration
- **High risk**: Schema output parity — need to diff generated YAML before/after to catch regressions

## Verification

1. Run full spec suite and confirm all 299 specs pass
2. Diff `swagger/*.yaml` output before/after — schemas should be equivalent
3. Verify API docs are accessible via the new engine routes
4. Check that `oasdiff` CI step still works
5. Test runtime middleware in staging (if enabled)
