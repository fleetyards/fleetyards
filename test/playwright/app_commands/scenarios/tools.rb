# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating tools scenario test data..."

Flipper.enable(:tools_travel_times)
Flipper.enable(:tools_cargo_grids)

# Ships with cargo holds (for cargo grids)
# Set cargo_holds YAML attribute via update so the before_save callback
# creates CargoHold DB records (can't set on create - parent must be saved first)
drak = Manufacturer.find_or_create_by!(name: "Drake Interplanetary") { |m| m.code = "DRAK" }
model = Model.find_or_initialize_by(name: "Caterpillar")
if model.new_record?
  model = FactoryBot.create(:model, :with_legacy_images, name: "Caterpillar", production_status: "flight-ready", manufacturer: drak)
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

misc = Manufacturer.find_or_create_by!(name: "Musashi Industrial & Starflight Concern") { |m| m.code = "MISC" }
freelancer_max = Model.find_or_initialize_by(name: "Freelancer MAX")
if freelancer_max.new_record?
  freelancer_max = FactoryBot.create(:model, :with_legacy_images, name: "Freelancer MAX", production_status: "flight-ready", manufacturer: misc)
end
freelancer_max.update!(cargo_holds: [
  {
    "name" => "cargo",
    "capacity" => 120,
    "dimensions" => {"x" => 12.5, "y" => 5.0, "z" => 5.0},
    "max_container_size" => {"size" => 32, "dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}}
  }
])

unless Model.exists?(name: "Aurora MR")
  rsi = Manufacturer.find_or_create_by!(name: "Roberts Space Industries") { |m| m.code = "RSI" }
  FactoryBot.create(:model, :with_legacy_images, name: "Aurora MR", production_status: "flight-ready", manufacturer: rsi)
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

Rails.logger.info "E2E: Created tools scenario test data"
