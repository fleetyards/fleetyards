# AGENTS.md

Best practices and conventions for AI agents working on the Fleetyards codebase. This file is the single source of truth for agentic coding — all AI tools (Claude Code, Cursor, Copilot, etc.) should follow these guidelines.

## Architecture Overview

- **Backend**: Ruby on Rails 7.x with PostgreSQL, Redis, Sidekiq
- **Frontend**: Vue.js 3 with Vite, TypeScript, Pinia, Tanstack Vue Query, Orval
- **API docs**: OpenAPI/Swagger (rswag)
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
├── spec/                      # RSpec tests
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
foreman start -f Procfile.dev     # Start Rails + Vite
bin/dev                           # Alternative: start dev environment
```

### Testing
```bash
rspec                             # Backend tests
pnpm test                         # Frontend tests (Vitest)
pnpm test:e2e:run                 # E2E tests (Playwright)
```

### Linting & Formatting
```bash
bundle exec standardrb --fix      # Ruby linting (always run after changing .rb files)
pnpm lint:fix                     # Frontend linting (ESLint + Stylelint + Prettier)
pnpm lint:ts                      # TypeScript type checking
pnpm format:fix                   # Prettier formatting
```

### API Schema
```bash
./bin/generate-schema             # Generate OpenAPI schema
```

## Backend Conventions

### Code Style
- Write concise, idiomatic Ruby following the [Ruby Style Guide](https://rubystyle.guide/)
- Use snake_case for files, methods, variables; CamelCase for classes/modules
- Prefer single quotes unless interpolation is needed
- Follow Rails MVC conventions; use concerns for shared behavior
- Use service objects for complex business logic

### Database & Performance
- Use database indexing effectively
- Use eager loading (`includes`, `joins`) to avoid N+1 queries
- Implement caching strategies (fragment caching, Russian Doll caching)
- Use Sidekiq for background jobs

### Testing
- Write RSpec tests for all new features (with rswag for API specs)
- Use FactoryBot for test data
- Place request specs in `spec/requests/`

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
- Use lowercase-with-dashes for directory names

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

1. **Write RSpec test first** in `spec/requests/` using `swagger_helper`
2. **Implement model methods** in `app/models/` if needed
3. **Add controller action** in `app/controllers/api/v1/`
4. **Update policy** in `app/policies/` for authorization
5. **Add route** in `config/routes/api/`
6. **Run linting**: `bundle exec standardrb --fix`
7. **Generate schema**: `./bin/generate-schema`
8. **Run tests**: `rspec`

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
- `.cursor/rules/frontend.mdc` — Frontend development rules
- `.cursor/rules/frontend/linting-and-formatting.mdc` — Frontend formatting
- `.cursor/rules/frontend/styling.mdc` — SCSS/styling rules
- `.cursor/rules/frontend/unit-test.mdc` — Frontend testing rules
- `.cursor/rules/frontend/vue-sfc.mdc` — Vue SFC conventions
- `.cursor/rules/frontend/components.mdc` — Shared component guidelines
- `.cursor/rules/git-workflow.mdc` — Git workflow and commit conventions
- `.cursor/rules/bin-scripts.mdc` — Development scripts
- `.cursor/rules/systematic_debugging.mdc` — Debugging methodology
