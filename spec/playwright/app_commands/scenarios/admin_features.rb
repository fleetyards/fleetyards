# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_features scenario test data..."

AdminUser.find_or_create_by!(username: "admin_features") do |u|
  u.email = "admin_features@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.super_admin = true
end

# Ensure feature flags exist
Flipper.add(:tools_cargo_grids) unless Flipper.exist?(:tools_cargo_grids)
Flipper.add(:tools_travel_times) unless Flipper.exist?(:tools_travel_times)

Rails.logger.info "E2E: Created admin_features scenario test data"
