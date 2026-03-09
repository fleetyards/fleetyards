# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_cargo_holds scenario test data..."

FactoryBot.create(:admin_user, username: "admin", email: "admin@test.com", password: "password123", password_confirmation: "password123", super_admin: true)

model = FactoryBot.create(:model, :with_legacy_images, name: "Caterpillar", production_status: "flight-ready")
FactoryBot.create(:cargo_hold, model: model, name: "cargo_front", dimension_x: 5.0, dimension_y: 2.5, dimension_z: 2.5, capacity_scu: 8, max_container_size_scu: 8)
FactoryBot.create(:cargo_hold, model: model, name: "cargo_rear", dimension_x: 10.0, dimension_y: 2.5, dimension_z: 2.5, capacity_scu: 16, max_container_size_scu: 16)

Model.reindex

Rails.logger.info "E2E: Created admin_cargo_holds scenario test data"
