# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_features scenario test data..."

AdminUser.find_or_create_by!(username: "admin_features") do |u|
  u.email = "admin_features@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.super_admin = true
end

# The page needs rows to render; these two are still gated, and both carry a
# self-service row, so it shows more than a bare boolean flag would.
Flipper.add(:fleet_logistics) unless Flipper.exist?(:fleet_logistics)
Flipper.add(:ship_inventories) unless Flipper.exist?(:ship_inventories)

Rails.logger.info "E2E: Created admin_features scenario test data"
