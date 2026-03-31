# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_cargo_holds scenario test data..."

AdminUser.find_or_create_by!(username: "admin_cargo") do |u|
  u.email = "admin_cargo@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.super_admin = true
end

model = Model.find_or_initialize_by(name: "Caterpillar")
if model.new_record?
  model = FactoryBot.create(:model, :with_legacy_images, name: "Caterpillar", production_status: "flight-ready")
end
model.update!(cargo_holds: [
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

Rails.logger.info "E2E: Created admin_cargo_holds scenario test data"
