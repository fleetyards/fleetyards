# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fleetyards.net is a Star Citizen ship database and web API built with Ruby on Rails 7.2+ and Vue.js 3. It provides a comprehensive database of ships, components, and game data from the Star Citizen universe.

## Architecture

### Backend (Rails)
- **Rails 7.2.2**: Main application framework
- **PostgreSQL**: Primary database
- **OpenSearch**: Search engine using Searchkick
- **Redis**: Caching and session storage
- **Sidekiq**: Background job processing
- **Puma**: Application server

### Frontend (Vue.js)
- **Vue 3**: Progressive JavaScript framework
- **Vite**: Frontend build tool and dev server
- **TypeScript**: Type-safe JavaScript
- **Pinia**: State management
- **Vue Router**: Client-side routing
- **TanStack Query**: Data fetching and caching

### Key Technologies
- **API**: OpenAPI/Swagger documented REST API
- **Authentication**: Devise with OAuth2 support (Discord, GitHub, Twitch)
- **Authorization**: Action Policy for permissions
- **File uploads**: CarrierWave with AWS S3 support
- **Feature flags**: Flipper for feature toggles
- **Testing**: RSpec (Rails), Vitest (Vue), Playwright (E2E)

## Development Commands

### Setup
```bash
# Install dependencies
bundle install
pnpm install

# Start development environment with Docker Compose
docker-compose up -d

# Database setup
rails db:create db:migrate db:seed

# Start development server
foreman start -f Procfile.dev
```

### Testing
```bash
# Run Ruby tests
rspec

# Run JavaScript tests
pnpm test

# Run E2E tests
pnpm test:e2e:run

# Run test coverage
pnpm test:coverage
```

### Linting & Type Checking
```bash
# Run all linting
pnpm lint

# Run JavaScript linting
pnpm lint:js

# Run TypeScript checking
pnpm lint:ts
pnpm vue-tsc
pnpm tsc

# Run prettier formatting
pnpm lint:prettier:fix

# Run Ruby linting and formatting
bundle exec standardrb --fix
```

### API & Documentation
```bash
# Generate API client
pnpm generate-api-client

# Generate API schema
./bin/generate-schema

# Validate OpenAPI schemas
pnpm validate-schema
pnpm validate-admin-schema
```

### Database & Background Jobs
```bash
# Run migrations
rails db:migrate

# Run background jobs
bundle exec sidekiq

# Database console
rails db

# Application console
rails console
```

## Code Structure

### API Architecture
- **Controllers**: RESTful API controllers in `app/controllers/api/v1/`
- **Serializers**: JSON responses using Jbuilder views in `app/views/api/v1/`
- **Policies**: Authorization logic using Action Policy in `app/policies/`
- **Models**: ActiveRecord models with concerns in `app/models/`

### Frontend Architecture
- **Components**: Vue components organized by feature in `app/frontend/`
- **Composables**: Reusable logic in `app/frontend/shared/composables/`
- **Stores**: Pinia stores for state management
- **Services**: API clients and utilities in `app/frontend/services/`

### Key Patterns
- **Ransack**: Advanced search and filtering for models
- **Kaminari**: Pagination for API responses
- **Feature Flags**: Use `feature_enabled?("flag-name")` for conditional features
- **Concerns**: Shared model and controller logic in concerns/
- **Filters**: Complex filtering using `useFilters` composable

### Important Files
- **Routes**: API routes defined in `config/routes/api/` directory
- **Factories**: Test factories in `spec/factories/`
- **Translations**: I18n files in `config/locales/` and `app/frontend/translations/`
- **Configuration**: App config in `config/app/main.yml`

## Data Loading & Jobs

### Background Jobs
- **Loaders**: Data import jobs in `app/jobs/loaders/`
- **Updaters**: Data sync jobs in `app/jobs/updater/`
- **Cleanup**: Maintenance jobs in `app/jobs/cleanup/`

### External Data Sources
- **RSI (Roberts Space Industries)**: Ship data and news
- **SC-API**: Star Citizen game data
- **YouTube**: Video content integration

## Development Notes

### Testing Strategy
- Use factories for test data creation
- API tests use request specs in `spec/requests/`
- Frontend tests use Vitest for unit tests
- E2E tests use Playwright

### Performance Considerations
- Use includes/joins for N+1 query prevention
- Implement caching for expensive operations
- Use background jobs for long-running tasks
- Optimize database queries with proper indexing

### Security
- API validation using Committee gem
- CORS configuration for frontend API access
- OAuth2 authentication with multiple providers
- Authorization policies for all resources

## Common Development Tasks

### Adding New API Endpoints
1. Create controller action in `app/controllers/api/v1/`
2. Add route in `config/routes/api/`
3. Create Jbuilder view in `app/views/api/v1/`
4. Add authorization policy if needed
5. Write request specs in `spec/requests/`
6. Update OpenAPI documentation with `./bin/generate-schema`

### Adding New Frontend Features
1. Create Vue component in appropriate feature directory
2. Add to router if needed
3. Create API service calls
4. Add translations
5. Write unit tests
6. Update E2E tests if needed

### Database Changes
1. Generate migration: `rails generate migration`
2. Update model associations and validations
3. Add factory updates
4. Update API serializers
5. Run tests to ensure compatibility