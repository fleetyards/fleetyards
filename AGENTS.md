# AGENTS.md

Best practices and conventions for AI agents working on the Fleetyards codebase. This file is the single source of truth for agentic coding — all AI tools (Claude Code, Cursor, Copilot, etc.) should follow these guidelines.

## Architecture Overview

- **Backend**: Ruby on Rails 7.x with PostgreSQL, Redis, Sidekiq
- **Frontend**: Vue.js 3 with Vite, TypeScript, Pinia, Tanstack Vue Query, Orval
- **API docs**: OpenAPI (openapi-ruby)
- **Auth**: Devise (authentication), Action Policy (authorization)
- **Package manager**: pnpm (never use npm)

## Project Structure

```
fleetyards/
├── app/
│   ├── models/                # ActiveRecord models
│   ├── controllers/           # Rails controllers (API in api/v1/)
│   ├── views/                 # Rails views
│   ├── helpers/               # View helpers
│   ├── mailers/               # Mailers
│   ├── jobs/                  # ActiveJob/Sidekiq jobs
│   ├── policies/              # Action Policy authorization
│   ├── uploaders/             # File uploaders
│   ├── channels/              # ActionCable channels
│   ├── api_components/        # API-specific code
│   ├── lib/                   # Custom libraries
│   ├── tasks/                 # Rake tasks
│   └── frontend/              # Frontend (Vue 3, TypeScript, SCSS)
│       ├── admin/             # Admin-specific frontend
│       ├── docs/              # Documentation pages
│       ├── embed/             # Embeddable widgets
│       ├── entrypoints/       # Vite entry points
│       ├── services/          # API and utility services
│       ├── shared/components/ # Shared Vue components
│       ├── stylesheets/       # Global SCSS styles
│       ├── translations/      # i18n translation files
│       └── types/             # TypeScript types
├── config/                    # Rails configuration
├── db/                        # Migrations, schema, seeds
├── test/                      # Minitest tests
├── bin/                       # Development scripts
└── .cursor/rules/             # Detailed rule files (see below)
```

## Essential Commands

### Setup
```bash
bundle install && pnpm install
rails db:create db:migrate db:seed
```

### Development
```bash
docker-compose up -d              # Start database and services
foreman start -f Procfile          # Start Rails + Vite
bin/dev                           # Alternative: start dev environment
```

### Testing
```bash
bin/rails test                    # Backend tests (Minitest)
pnpm test                         # Frontend tests (Vitest)
pnpm test:e2e:run                 # E2E tests (Playwright)
```

### Deployment & Remote Operations
```bash
bin/deploy-stage                  # Deploy to staging
bin/deploy                        # Deploy to production
bin/exec-stage <role> -- <cmd>    # Run command on staging (e.g. bin/exec-stage web -- bundle exec rails console)
bin/exec-live <role> -- <cmd>     # Run command on production
bin/console-stage                 # Rails console on staging
bin/console-live                  # Rails console on production
bin/logs-stage                    # View staging logs
bin/logs-live                     # View production logs
bin/setup-stage                   # Run Kamal setup for staging
bin/setup-live                    # Run Kamal setup for production
```

### Linting & Formatting
```bash
bundle exec standardrb --fix      # Ruby linting (always run after changing .rb files)
pnpm lint:fix                     # Frontend linting (ESLint + Prettier; no Stylelint, see below)
pnpm lint:ts                      # TypeScript type checking
pnpm format:fix                   # Prettier formatting
```

### API Schema
```bash
./bin/generate-schema             # Generate OpenAPI schema
```

## Backend Conventions

### Code Style
- Write concise, idiomatic Ruby following [standardrb](https://github.com/standardrb/standard) — the project's linter is the source of truth for style
- Use snake_case for files, methods, variables; CamelCase for classes/modules
- String quoting follows standardrb's default (double quotes); don't fight the formatter
- Follow Rails MVC conventions; use concerns for shared behavior
- Use service objects for complex business logic

### Database & Performance
- Use database indexing effectively
- Use eager loading (`includes`, `joins`) to avoid N+1 queries
- Implement caching strategies (fragment caching, Russian Doll caching)
- Use Sidekiq for background jobs

### Testing
- Write Minitest tests for all new features. API endpoints get integration tests in `test/integration/` using `openapi-ruby` (`include OpenapiRuby::Adapters::Minitest::DSL`) so the OpenAPI schema is generated from the same specs.
- Use FactoryBot for test data (factories live in `test/factories/`)
- Run the suite with `bin/rails test` or target a file with `bin/rails test path/to/file_test.rb`

### Security
- Use strong parameters in controllers
- Use Devise for authentication, Action Policy for authorization
- Protect against XSS, CSRF, SQL injection

### Linting
- **Always** run `bundle exec standardrb --fix <changed_files>` after modifying Ruby files

## Frontend Conventions

### Vue Components
- Add a component name in a separate `<script lang="ts">` block at the top
- Use `<script lang="ts" setup>` for all logic (note: `lang` before `setup`)
  ```vue
  <script lang="ts">
  export default {
    name: "MyComponent",
  };
  </script>

  <script lang="ts" setup>
  // component logic here
  </script>
  ```
- Use `<style lang="scss" scoped>` for styles
- PascalCase for component file names
- One component per file; keep components focused and small
- Use composables for reusable logic
- Use props and emits with full TypeScript typing

### TypeScript
- Use TypeScript for all code
- Prefer interfaces over types for extendability
- Use functional and declarative patterns; avoid classes
- Use descriptive variable names (e.g., `isLoading`, `hasError`)

### Styling
- Use SCSS with lowercase-dashed class names (e.g., `.panel-heading`)
- Write custom SCSS instead of relying on Bootstrap utility classes
- Align naming and patterns with Tailwind CSS conventions to ease a future migration
- Use variables/mixins from `stylesheets/variables.scss`
- Keep specificity low; avoid deep selector nesting

### Component Organization
- Shared components live in `app/frontend/shared/components/`
- Each component gets its own directory with `index.vue`, optional `index.scss`, `types.ts`
- Component directory names use PascalCase (or a descriptive name) — matches the existing tree (`Manufacturers/`, `OauthBtn/`, `AdminUsers/`, `base/`, …). See `.cursor/rules/frontend/components.mdc` for the full rule.

### Auto-imports
- Vue core functions (`ref`, `onMounted`, etc.) are auto-imported — do not import them manually
- Check `vite.config.ts` for configured auto-imports

### Testing
- Use Vitest with Vue Test Utils
- Place test files next to the code they test (`.spec.ts` or `.test.ts`)
- Mock API calls and external dependencies
- Use `describe` blocks to group related tests

### API Client Generation (Orval)
- Orval generates TypeScript API clients and types from the OpenAPI schema
- Config: `orval.config.ts` defines two APIs: `fyApi` (public) and `fyAdminApi` (admin)
- Generated output: `app/frontend/services/fyApi/` and `app/frontend/services/fyAdminApi/`
- Uses Tanstack Vue Query as the client (`client: "vue-query"`)
- Generated files are split by tags (`mode: "tags-split"`)
- **Never edit generated files** — regenerate with Orval after schema changes
- After updating API endpoints and regenerating the OpenAPI schema, re-run Orval to update the frontend clients

### Linting
- **Always** run `pnpm lint:fix` after modifying frontend files
- Use `pnpm lint:ts` for TypeScript type checking
- Note: `type-check` and `typecheck` commands do not exist in this project
- SCSS is **not** linted. Four stylelint packages are in devDependencies but the
  repo has no stylelint config, so nothing runs them and `stylelint` on a file
  fails with "No configuration provided". Treat stylesheet conventions as
  reviewed by eye, not enforced.

## Git Workflow

### Branch Naming
```
feat/[short-description]      # New features
fix/[short-description]       # Bug fixes
refactor/[short-description]  # Refactoring
docs/[short-description]      # Documentation
test/[short-description]      # Tests
chore/[short-description]     # Maintenance
```

### Commit Messages
Follow conventional commits:
```
<type>(<scope>): <short summary>

<optional body>

<optional footer>
```
Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## API Development Workflow

When adding new API endpoints, follow this order:

1. **Write a Minitest integration test first** in `test/integration/` using `openapi-ruby`'s DSL (`include OpenapiRuby::Adapters::Minitest::DSL`)
2. **Implement model methods** in `app/models/` if needed
3. **Add controller action** in `app/controllers/api/v1/`
4. **Update policy** in `app/policies/` for authorization
5. **Add route** in `config/routes/api/`
6. **Add OpenAPI components** in `app/api_components/` — never edit `swagger/*.yaml` directly
7. **Run linting**: `bundle exec standardrb --fix`
8. **Generate schema**: `./bin/generate-schema`
9. **Run tests**: `bin/rails test`

### Never define request or response types inline

Every request body and every response body must be a `$ref` to an explicit
component class under `app/api_components/`. The integration test declares the
reference, never the shape:

```ruby
# Good
request_body required: true, schema: {"$ref": "#/components/schemas/ModelLinkInput"}

response(200, "successful") do
  schema "$ref": "#/components/schemas/MessageResponse"
end

# Bad — the shape lives in the test
request_body required: true, schema: {
  type: :object,
  properties: {modelId: {type: :string, format: :uuid}},
  required: [:modelId]
}
```

Why: an inline body has no name, so Orval invents one from the operation —
`UnlinkModelModuleBody`, `ReloadLoaners200`, `FleetCalendar200`. Four endpoints
sharing one payload get four unrelated TypeScript types that drift
independently, and the frontend has nothing stable to import.

That includes a response that is only an array. Give it a `<Plural>List`
component rather than wrapping the item `$ref` in the test:

```ruby
# Good
response(200, "successful") do
  schema "$ref": "#/components/schemas/FilterOptionsList"
end

# Bad — the cardinality lives in the test
response(200, "successful") do
  schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
end
```

One component per item type, shared by every endpoint returning that array.
Where the plural is already taken by the paginated collection (`Models`,
`Images`, `FleetMembersList`), the bare array gets the `List` suffix or a name
from what it returns — `ModelsList`, `ImagesList`, `FleetInvitesList`.

Naming and placement follow the existing tree:

- Request bodies → `<scope>/v1/schemas/inputs/<name>_input.rb`
- Response bodies → `<scope>/v1/schemas/<name>.rb`
- Array-only responses → `<scope>/v1/schemas/<name>_list.rb`
- Reused by both the public and the admin schema → `shared/v1/`
- Enums → `<scope>/v1/schemas/enums/<name>_enum.rb`, referenced by `$ref` —
  don't inline an `enum:` into a property
- Nested objects → their own component too. A `type: :object` with named
  properties inside another component is as anonymous as an inline body

### Nested objects

An object nested inside a component is a component as well. `Model.metrics` held
33 properties inline, and Orval reproduced the whole block once per owner —
`ComponentControllerPowerRangesHigh`, `ComponentCoolerPowerRangesHigh` and six
more siblings for a shape that is two numbers.

Two traps:

- **Inheritance cannot merge into a `$ref`.** openapi-ruby deep-merges a
  subclass's schema into its parent's, so pointing a parent property at a
  component leaves the subclass emitting a `$ref` *beside* the properties it
  meant to add. Give the subclass its own component that inherits the shared one
  (`AdminModelMedia < Shared::V1::Schemas::ModelMedia`).
- **A subclass in another scope inherits the reference.** An enum or object a v1
  component points at has to live in `shared/v1/` if any admin component
  subclasses that v1 component — otherwise the admin document carries a dangling
  `$ref`. Check with a ref-vs-defined diff over the generated specs.

Free-form maps stay inline: `{type: :object, additionalProperties: …}` has no
named properties, so there is nothing to name.

### Enum components

Put the enum in the **narrowest scope that reaches it**: `v1/schemas/enums/`,
`admin/v1/schemas/enums/`, `oauth/v1/schemas/enums/`, and `shared/v1/` only when
both the public and the admin schema reference it. openapi-ruby emits every
registered component whether or not it is referenced, so a `shared/v1` enum used
by one schema is dead weight in the other. Watch for the admin components that
subclass a v1 one (`Admin::V1::Schemas::Models::Model < ::V1::Schemas::Models::Model`):
they inherit its `$ref`s, so an enum they reach has to be `shared/v1`.

Source the values from the Rails model whenever it has them
(`::Mission.categories.keys`, `::FleetEvent::VISIBILITIES`) rather than
re-typing the list — a schema-local copy silently drifts from the validation.

A **nullable** enum gets its own `Nullable<Name>Enum` component holding
`type: [:string, :null]` and `VALUES + [nil]`. Do not write
`anyOf: [{$ref}, {type: :null}]`: oasdiff does not resolve enum values through
`anyOf`, so the breaking-change check reads every value as removed.

Two things stay inline: a **single-value discriminator** (`enum: %w[failed]` on
one message variant) is a constant, not an enum, and `FeatureFlagName` is
deliberately referenced by nothing — see the comment in that file.

Before adding a component, check whether one already fits: `SortInput`,
`StandardError`, `SuccessResponse`, `MessageResponse` and the `BaseList` /
`Meta` pair cover most small payloads.

A deepObject query parameter is no exception — it carries a plain `$ref` to a
`<Name>Query` component and nothing else. The `type: :object` that used to sit
next to the `$ref` was redundant; dropping it produces an identical document.

```ruby
parameter name: "q", in: :query,
  schema: {"$ref": "#/components/schemas/ModelQuery"},
  style: :deepObject, explode: true, required: false
```

Query components must spell out their properties. Request validation coerces the
strings a query string delivers only for **declared properties** — a map typed
through `additionalProperties` rejects every request, whatever the value type
says. `ContainerFitQuery` lists its seven keys for exactly that reason.

### Reference components by class, not by string

`$ref` strings work, but the DSL and `schema({})` both accept the component
class itself and turn it into the same `$ref`:

```ruby
status: V1::Schemas::Enums::HangarSyncStatusEnum
```

A typo is then a `NameError` at generate time instead of a dangling reference
that only `strict_reference_validation` warns about.

Use the class form. The exception is a name that exists in two scopes (`Model`,
`StandardError`, `User`, …): there a string ref is deliberately late-bound, so it
resolves per document. Those stay strings.

## Feature Flags

Flags are declared in **`config/feature_flags.yml`** — the single source of truth.
`FeatureFlags::Synchronizer` reconciles Flipper with it on every deploy
(`.kamal/hooks/pre-deploy` runs `bin/feature-flags sync`). Full reference:
[lib/feature_flags/README.md](lib/feature_flags/README.md).

To add a flag:

1. Add an entry with a `description` (plus `permanent: true` for long-lived
   infrastructure gates like the OAuth providers):

   ```yaml
   my_new_flag:
     description: "What this toggles"
   ```

2. Validate with `bin/feature-flags validate`; CI runs the same command.
3. Run `bin/feature-flags sync` to create it in your dev database.
4. Read it as usual — `Flipper.enabled?(:my_new_flag, actor)` in Ruby,
   `isFeatureEnabled('my_new_flag')` in Vue.

Flags are created **off** and with no self-service toggle. Everything about a
flag's behaviour is decided at `/admin/features`: its gates, and a self-service
switch per surface — **Users can toggle** for a personal one, **Fleet admins can
toggle** for a fleet-wide one, either or both. The registry declares none of it,
and sync never writes `feature_settings`. Read a fleet feature against the fleet
(`isFleetFeatureEnabled(fleet, …)` in Vue, off the fleet payload's `features`).

To remove a flag, delete its entry — the next deploy prunes the Flipper feature,
all of its gate values and its `FeatureSetting` row (irreversible).

**Do not** write a `Flipper.add` or `FeatureSetting` data migration. The registry
owns flag lifecycle; a migration creates state the registry doesn't know about,
which the next sync prunes. The existing `db/data/*_feature_flag.rb` migrations
predate the registry — leave them, don't add more.

## Debugging Protocol

Before making changes to fix issues, follow a structured approach:

1. **Analyze first** — never start modifying files without understanding the problem
2. **Document** the error messages, recent changes, and involved files
3. **Hypothesize** — form a theory about the root cause
4. **Plan** specific debug steps with expected outcomes
5. **Execute** step by step, verifying at each stage
6. **No scope creep** — stay focused on the specific issue; don't fix unrelated things

## Agentic Best Practices

### Before Writing Code
- Read and understand existing code before modifying it
- Check existing patterns in the codebase and follow them
- Consult the detailed `.cursor/rules/` files for specific domain guidance

### While Writing Code
- Keep changes minimal and focused — don't refactor unrelated code
- Write tests for all new features and endpoints
- Use feature flags for experimental features
- Use factories for test data

### After Writing Code
- Run the appropriate linter (`standardrb --fix` for Ruby, `pnpm lint:fix` for frontend)
- Run relevant tests to verify changes
- Generate API schema if API endpoints were modified

### Detailed Rule Files
For deeper guidance on specific topics, refer to:
- `.cursor/rules/tech-stack.mdc` — Full technology stack details
- `.cursor/rules/project-structure.mdc` — Project structure details
- `.cursor/rules/backend.mdc` — Backend development rules
- `.cursor/rules/backend/linting-and-formatting.mdc` — Ruby formatting
- `.cursor/rules/backend/api-components.mdc` — OpenAPI component placement and the no-inline-schema rule
- `.cursor/rules/frontend.mdc` — Frontend development rules
- `.cursor/rules/frontend/linting-and-formatting.mdc` — Frontend formatting
- `.cursor/rules/frontend/styling.mdc` — SCSS/styling rules
- `.cursor/rules/frontend/unit-test.mdc` — Frontend testing rules
- `.cursor/rules/frontend/vue-sfc.mdc` — Vue SFC conventions
- `.cursor/rules/frontend/components.mdc` — Shared component guidelines
- `.cursor/rules/git-workflow.mdc` — Git workflow and commit conventions
- `.cursor/rules/bin-scripts.mdc` — Development scripts
- `.cursor/rules/systematic_debugging.mdc` — Debugging methodology
