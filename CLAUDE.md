# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Key Reference Files

For detailed development guidelines, refer to these files:

### Core Architecture
- **Technology Stack**: @.cursor/rules/tech-stack.mdc
- **Project Structure**: @.cursor/rules/project-structure.mdc
- **Git Workflow**: @.cursor/rules/git-workflow.mdc
- **Development Scripts**: @.cursor/rules/bin-scripts.mdc
- **Systematic Debugging**: @.cursor/rules/systematic_debugging.mdc

### Backend Development
- **Backend Guidelines**: @.cursor/rules/backend.mdc
- **Backend Formatting**: @.cursor/rules/backend/linting-and-formatting.mdc

### Frontend Development
- **Frontend Guidelines**: @.cursor/rules/frontend.mdc
- **Frontend Formatting**: @.cursor/rules/frontend/linting-and-formatting.mdc
- **Frontend Styling**: @.cursor/rules/frontend/styling.mdc
- **Frontend Testing**: @.cursor/rules/frontend/unit-test.mdc
- **Vue Components**: @.cursor/rules/frontend/vue-sfc.mdc
- **Frontend Components**: @.cursor/rules/frontend/components.mdc


## Essential Development Commands

### Setup
```bash
bundle install
pnpm install
rails db:create db:migrate db:seed
```

### Database Operations
```bash
rails db:reset               # Reset database
rails db:migrate:reset       # Reset and migrate
```

### Development Servers
```bash
docker-compose up -d         # Start database and services
foreman start -f Procfile.dev # Start Rails + Vite
```

### Testing & Quality
```bash
rspec                        # Backend tests (RSpec)
pnpm test                    # Frontend tests (Vitest)
pnpm test:e2e:run            # E2E tests (Playwright)
pnpm lint                    # Frontend linting
bundle exec standardrb --fix # Ruby linting
COVERAGE=true rspec          # Backend coverage
pnpm test:coverage           # Frontend coverage
```

### API & Documentation
```bash
./bin/generate-schema        # Generate OpenAPI schema
```

## Quick Architecture Overview

- **Rails 7.x** backend with PostgreSQL, Redis, Sidekiq
- **Vue.js 3** frontend with Vite, TypeScript, Pinia
- **OpenAPI/Swagger** for API documentation
- **Devise** for authentication, **Action Policy** for authorization
- **pnpm** package manager (never use npm)

## Key Conventions

- Use `<script setup>` syntax for all Vue components
- Follow all conventions in the referenced .mdc rule files
- Write tests for all new features and endpoints
- Use feature flags for experimental features
- Use factories for test data

## API Development Workflow

When adding new API endpoints:

1. **Write RSpec test first** in `spec/requests/` using `swagger_helper`
2. **Implement model methods** in `app/models/` if needed
3. **Add controller action** in `app/controllers/api/v1/`
4. **Update policy** in `app/policies/` for authorization
5. **Add route** in `config/routes/api/`
6. **Run linting** with `bundle exec standardrb --fix` to fix Ruby style issues
7. **Generate schema** with `./bin/generate-schema`
8. **Run tests** with `rspec`

> For further details on code style, structure, or process, consult the relevant rule file above for authoritative guidance.
