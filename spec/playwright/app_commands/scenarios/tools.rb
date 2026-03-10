# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating tools scenario test data..."

Flipper.enable(:tools_travel_times)
Flipper.enable(:tools_cargo_grids)

# Ships with cargo holds (for cargo grids)
# Set cargo_holds YAML attribute so the API returns cargo hold data
# and the before_save callback creates CargoHold DB records
model = FactoryBot.create(:model, :with_legacy_images, name: "Caterpillar", production_status: "flight-ready", cargo_holds: [
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
