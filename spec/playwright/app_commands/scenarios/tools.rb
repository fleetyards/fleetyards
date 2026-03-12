# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating tools scenario test data..."

Flipper.enable(:tools_travel_times)
Flipper.enable(:tools_cargo_grids)

# Ships with cargo holds (for cargo grids)
# Set cargo_holds YAML attribute via update so the before_save callback
# creates CargoHold DB records (can't set on create - parent must be saved first)
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

unless Model.exists?(name: "Aurora MR")
  FactoryBot.create(:model, :with_legacy_images, name: "Aurora MR", production_status: "flight-ready")
end

# Quantum drives (for travel times)
unless Component.exists?(name: "Beacon")
  FactoryBot.create(:component, name: "Beacon", item_type: "quantum_drives", type_data: {
    "fuel_rate" => 80.0,
    "standard_jump" => {
      "speed" => 283046000,
      "stage_1_acceleration_rate" => 49500000,
      "stage_2_acceleration_rate" => 1500000
    }
  })
end

unless Component.exists?(name: "Expedition")
  FactoryBot.create(:component, name: "Expedition", item_type: "quantum_drives", type_data: {
    "fuel_rate" => 60.0,
    "standard_jump" => {
      "speed" => 183046000,
      "stage_1_acceleration_rate" => 39500000,
      "stage_2_acceleration_rate" => 1200000
    }
  })
end

Component.reindex
Model.reindex

Rails.logger.info "E2E: Created tools scenario test data"
