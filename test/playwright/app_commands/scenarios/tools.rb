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
    "max_container_size" => {"size" => 8, "dimensions" => {"x" => 2.0, "y" => 2.0, "z" => 2.0}},
    "limits" => {
      "min" => {"dimensions" => {"x" => 1.0, "y" => 1.0, "z" => 1.0}, "capacity" => 1},
      "max" => {"dimensions" => {"x" => 2.0, "y" => 2.0, "z" => 2.0}, "capacity" => 8}
    }
  },
  {
    "name" => "cargo_rear",
    "capacity" => 16,
    "dimensions" => {"x" => 10.0, "y" => 2.5, "z" => 2.5},
    "max_container_size" => {"size" => 16, "dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}},
    "limits" => {
      "min" => {"dimensions" => {"x" => 1.0, "y" => 1.0, "z" => 1.0}, "capacity" => 1},
      "max" => {"dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}, "capacity" => 16}
    }
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
    "max_container_size" => {"size" => 32, "dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}},
    "limits" => {
      "min" => {"dimensions" => {"x" => 1.0, "y" => 1.0, "z" => 1.0}, "capacity" => 1},
      "max" => {"dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}, "capacity" => 32}
    }
  }
])

unless Model.exists?(name: "Aurora MR")
  rsi = Manufacturer.find_or_create_by!(name: "Roberts Space Industries") { |m| m.code = "RSI" }
  FactoryBot.create(:model, :with_legacy_images, name: "Aurora MR", production_status: "flight-ready", manufacturer: rsi)
end

# Quantum drives (for travel times). The travel times page selects on
# `category`, and reads the flat `drive_speed` / `stage_*_accel_rate` keys the
# sc_data parser writes -- mirroring a loaded drive here, or the page renders
# "-:-:-" for every row. `quantum_fuel_consumption` is milli-SCU per Gm; 5 and
# 22 are the values real S1 and S2 drives carry.
unless Component.exists?(name: "Beacon")
  FactoryBot.create(:component, name: "Beacon", category: "quantumdrive", component_type: "QuantumDrive", type_data: {
    "quantum_fuel_consumption" => 5.0,
    "drive_speed" => 283046000.0,
    "stage_one_accel_rate" => 49500000.0,
    "stage_two_accel_rate" => 1500000.0
  })
end

unless Component.exists?(name: "Expedition")
  FactoryBot.create(:component, name: "Expedition", category: "quantumdrive", component_type: "QuantumDrive", type_data: {
    "quantum_fuel_consumption" => 22.0,
    "drive_speed" => 183046000.0,
    "stage_one_accel_rate" => 39500000.0,
    "stage_two_accel_rate" => 1200000.0
  })
end

Rails.logger.info "E2E: Created tools scenario test data"
