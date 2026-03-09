# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_features scenario test data..."

FactoryBot.create(:admin_user, username: "admin", email: "admin@test.com", password: "password123", password_confirmation: "password123", super_admin: true)

# Ensure feature flags exist
Flipper.add(:tools_cargo_grids) unless Flipper.exist?(:tools_cargo_grids)
Flipper.add(:tools_travel_times) unless Flipper.exist?(:tools_travel_times)

Rails.logger.info "E2E: Created admin_features scenario test data"
