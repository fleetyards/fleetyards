# Remove OpenSearch / Searchkick Dependency

The `/api/v1/search` endpoint is the only consumer of Searchkick. It is no longer used by the frontend. Removing it eliminates the OpenSearch infrastructure dependency entirely.

## Phase 1: Remove the search endpoint

### API
- Delete `app/controllers/api/v1/search_controller.rb`
- Delete `app/views/api/v1/search/` (index.jbuilder, _base.jbuilder, _search.jbuilder)
- Remove `resources :search` from `config/routes/api/v1_routes.rb:53`
- Remove `resources :search` from `config/routes/admin/api/v1_routes.rb:70`

### Pagination guard
- Remove the `Searchkick::Relation` check in `app/views/api/shared/_pagination.jbuilder:6`

## Phase 2: Remove Searchkick from models

### Model (`app/models/model.rb`)
- Remove `searchkick` declaration (~line 172-173)
- Remove `def search_data` method

### Component (`app/models/component.rb`)
- Remove `searchkick` declaration (~line 47-49)
- Remove `def search_data` method

### Equipment (`app/models/equipment.rb`)
- Remove `searchkick` declaration (~line 41-42)
- Remove `def search_data` method

## Phase 3: Remove gems and configuration

### Gems
- Remove `gem "searchkick"` from `Gemfile:19`
- Remove `gem "opensearch-ruby"` from `Gemfile:18`
- Run `bundle install` to update `Gemfile.lock` and `gemset.nix`

### Initializers
- Delete `config/initializers/searchkick.rb`
- Delete `config/initializers/opensearch.rb`

### App config
- Remove `opensearch_url` from `config/app/main.yml:27`

## Phase 4: Remove from CI, setup, and deploy scripts

### CI workflows
- `.github/workflows/ruby-tests.job.yml` — remove `ankane/setup-opensearch` step
- `.github/workflows/e2e.job.yml` — remove `OPENSEARCH_URL` env var, `ankane/setup-opensearch` step, and `searchkick:reindex:all` commands
- `.github/workflows/seeds.job.yml` — remove `OPENSEARCH_URL` env var, `ankane/setup-opensearch` step, and `searchkick:reindex:all` command

### bin/setup
- Remove `active_worktree_opensearch_prefixes` method
- Remove `cleanup_stale_worktree_indices` method (or its OpenSearch-specific logic)
- Remove the "Cleaning stale Opensearch indices" step (~line 409)
- Remove the "Reindexing Opensearch" steps (~lines 413-416)

### Docker
- Remove `opensearch` service from `docker-compose.yml` (service + volume)
- Remove `searchkick:reindex:all` from `docker/entrypoint.sh:16`

### Kamal (branch `chore/kamal-deployment`)
- Remove `OPENSEARCH_URL` from `env.secret` in `config/deploy.yml`
- Remove the `opensearch` accessory from `config/deploy.yml`
- Remove `OPENSEARCH_URL` secret from `.github/workflows/deploy.job.yml`
- Remove `searchkick:reindex:all` from `docker/entrypoint.sh`

### Capistrano (legacy)
- Remove `searchkick:reindex:all` from `config/deploy.rb:195` (or the entire reindex task if that's all it does)

### Environment files
- Remove `OPENSEARCH_URL` from `.env.example:8`
- Remove `OPENSEARCH_URL` from `.env.test:7`

## Phase 5: Test cleanup

### spec/rails_helper.rb
- Remove `Searchkick.disable_callbacks` (~line 16)
- Remove `Searchkick.disable_callbacks` in config block (~line 79)
- Remove `Searchkick.callbacks(nil)` block (~line 84)

### Run test suite
- Verify no remaining references to Searchkick or OpenSearch
- Ensure all tests pass without OpenSearch running
