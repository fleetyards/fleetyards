# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating tools scenario test data..."

Flipper.enable(:tools_travel_times)
Flipper.enable(:tools_cargo_grids)

# Ships with cargo holds (for cargo grids)
model = FactoryBot.create(:model, :with_legacy_images, name: "Caterpillar", production_status: "flight-ready")
FactoryBot.create(:cargo_hold, model: model, name: "cargo_front", dimension_x: 5.0, dimension_y: 2.5, dimension_z: 2.5, capacity_scu: 8, max_container_size_scu: 8)
FactoryBot.create(:cargo_hold, model: model, name: "cargo_rear", dimension_x: 10.0, dimension_y: 2.5, dimension_z: 2.5, capacity_scu: 16, max_container_size_scu: 16)

FactoryBot.create(:model, :with_legacy_images, name: "Aurora MR", production_status: "flight-ready")

# Quantum drives (for travel times)
FactoryBot.create(:component, name: "Beacon", item_type: "quantum_drives", type_data: {
  "fuel_rate" => 80.0,
  "standard_jump" => {
    "speed" => 283046000,
    "stage_1_acceleration_rate" => 49500000,
    "stage_2_acceleration_rate" => 1500000
  }
})

FactoryBot.create(:component, name: "Expedition", item_type: "quantum_drives", type_data: {
  "fuel_rate" => 60.0,
  "standard_jump" => {
    "speed" => 183046000,
    "stage_1_acceleration_rate" => 39500000,
    "stage_2_acceleration_rate" => 1200000
  }
})

Component.reindex
Model.reindex

Rails.logger.info "E2E: Created tools scenario test data"
