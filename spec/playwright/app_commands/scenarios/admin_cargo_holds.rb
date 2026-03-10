# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_cargo_holds scenario test data..."

FactoryBot.create(:admin_user, username: "admin", email: "admin@test.com", password: "password123", password_confirmation: "password123", super_admin: true)

FactoryBot.create(:model, :with_legacy_images, name: "Caterpillar", production_status: "flight-ready", cargo_holds: [
  {
    "name" => "cargo_front",
    "capacity" => 8,
    "dimensions" => {"x" => 5.0, "y" => 2.5, "z" => 2.5},
    "max_container_size" => {"size" => 8, "dimensions" => {"x" => 2.0, "y" => 2.0, "z" => 2.0}}
  },
  {
    "name" => "cargo_rear",
    "capacity" => 16,
    "dimensions" => {"x" => 10.0, "y" => 2.5, "z" => 2.5},
    "max_container_size" => {"size" => 16, "dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}}
  }
])

Model.reindex

Rails.logger.info "E2E: Created admin_cargo_holds scenario test data"
