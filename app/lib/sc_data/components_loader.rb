module ScData
  class ComponentsLoader < ::ScData::BaseLoader
    attr_accessor :translations_loader

    def initialize
      super

      self.translations_loader = ::ScData::TranslationsLoader.new
    end

    def load(sc_identifier)
      component_data = load_from_export("v2/items/#{sc_identifier.downcase}.json")

      extract_component!(component_data)
    end

    def extract_component!(component_data)
      return if component_data.blank?

      name = component_data["Name"]
      name = translations_loader.translate(name) if needs_translation?(name)

      return if name == "<= PLACEHOLDER =>"

      component = Component.find_or_create_by!(
        sc_identifier: component_data["ClassName"],
        name:
      )

      manufacturer = extract_manufacturer(component_data["Manufacturer"])

      description = component_data["Description"]
      description = translations_loader.translate(description) if needs_translation?(description)

      component.update!(
        size: component_data["Size"],
        grade: component_data["Grade"],
        item_class: extract_item_class(description),
        description:,
        manufacturer: manufacturer || component.manufacturer,
        item_type: item_type_mapping(component_data["Type"], component_data["Types"]),
        component_class: component_class_mapping(component_data["Class"], component_data["Types"]),
        type_data: extract_type_data(component_data),
        durability: extract_durability(component_data),
        power_connection: extract_power_connection(component_data),
        heat_connection: extract_heat_connection(component_data),
        ammunition: extract_ammunition(component_data)
      )

      component
    end

    private def extract_item_class(description)
      description&.scan(/Class: ((\w|\s)+)\\n/)&.last&.first
    end

    private def extract_type_data(component_data)
      %w[
        Shield MissileRack Missile Weapon PowerPlant Cooler QuantumDrive QuantumFuelTank Thruster
        HydrogenFuelTank HydrogenFuelIntake CargoGrid Radar QuantumInterdiction Emp
      ].filter_map do |type_data_key|
        component_data[type_data_key]
      end.first&.transform_keys(&:underscore)
    end

    private def extract_durability(component_data)
      component_data["Durability"]&.transform_keys(&:underscore)
    end

    private def extract_power_connection(component_data)
      component_data["PowerConnection"]&.transform_keys(&:underscore)
    end

    private def extract_heat_connection(component_data)
      component_data["HeatConnection"]&.transform_keys(&:underscore)
    end

    private def extract_ammunition(component_data)
      component_data["Ammunition"]&.transform_keys(&:underscore)
    end

    private def component_class_mapping(class_name, fallback_types = [])
      class_mapping = {
        "Shield generators" => "RSIModular",
        "Armor" => "RSIModular",
        "Power plants" => "RSIModular",
        "Cargo grids" => "RSIModular",
        "Missile racks" => "RSIWeapon",
        "Missiles" => "RSIWeapon",
        "Manned turrets" => "RSIWeapon",
        "Remote turrets" => "RSIWeapon",
        "Weapon hardpoints" => "RSIWeapon",
        "EMP hardpoints" => "RSIWeapon",
        "Countermeasures" => "RSIWeapon",
        "UtilityTurret.MannedTurret" => "RSIWeapon",
        "Mining hardpoints" => "RSIWeapon",
        "Scanners" => "RSIAvionic",
        "Radars" => "RSIAvionic",
        "Quantum drives" => "RSIPropulsion",
        "Fuel intakes" => "RSIPropulsion",
        "Fuel tanks" => "RSIPropulsion",
        "Quantum fuel tanks" => "RSIPropulsion",
        "Main thrusters" => "RSIThruster",
        "Maneuvering thrusters" => "RSIThruster",
        "Retro thrusters" => "RSIThruster",
        "VTOL thrusters" => "RSIThruster"
      }

      return class_mapping[class_name] if class_mapping[class_name].present?

      if fallback_types.present?
        found_type = fallback_types.find do |fallback_type|
          class_mapping[fallback_type].present?
        end

        return class_mapping[found_type] if found_type.present?
      end

      nil
    end

    private def item_type_mapping(type, fallback_types = [])
      type_mapping = {
        "Shield.UNDEFINED" => "shield_generators",
        "Cooler.UNDEFINED" => "coolers",
        "PowerPlant.Power" => "power_plants",
        "QuantumDrive.UNDEFINED" => "quantum_drives",
        "WeaponGun.Gun" => "weapons",
        "TurretBase.MannedTurret" => "manned_turrets",
        "Turret.GunTurret" => "remote_turrets",
        "Turret.MissileTurret" => "missile_turrets",
        "Missile.Missile" => "missiles",
        "MissileLauncher.MissileRack" => "missile_racks",
        "WeaponMining.Gun" => "mining_lasers",
        "UtilityTurret.MannedTurret" => "manned_utility_turrets",
        "Armor.Medium" => "armor_medium",
        "FuelIntake.Fuel" => "fuel_intakes",
        "Fuel tanks" => "fuel_tanks",
        "QuantumFuelTank.QuantumFuel" => "quantum_fuel_tanks",
        "Scanners" => "scanners",
        "Radar.MidRangeRadar" => "mid_range_radar",
        "MainThruster.FixedThruster" => "thrusters",
        "EMP.UNDEFINED" => "emp",
        "EMP" => "emp",
        "ManneuverThruster.JointThruster" => "joint_thrusters",
        "ManneuverThruster.FixedThruster" => "fixed_thrusters",
        # "" => "weapon_defensive",
        "WeaponDefensive.CountermeasureLauncher" => "countermeasure_launcher",
        "CargoGrid.UNDEFINED" => "cargo_grids",
        "CargoGrid" => "cargo_grids"
      }

      if type_mapping[type].present?
        return type_mapping[type]
      end

      if fallback_types.present?
        found_type = fallback_types.find do |fallback_type|
          type_mapping[fallback_type].present?
        end

        return type_mapping[found_type] if found_type.present?
      end

      nil
    end

    private def needs_translation?(string)
      return false if string.blank?

      string.start_with?("@")
    end

    private def extract_manufacturer(manufacturer_data)
      return if manufacturer_data.blank?

      manufacturer = Manufacturer.find_by(code: manufacturer_data["Code"])
      manufacturer = Manufacturer.find_by(code_mapping: manufacturer_data["Code"]) if manufacturer.blank?
      manufacturer = Manufacturer.find_by(name: manufacturer_data["Name"]) if manufacturer.blank?
      manufacturer = Manufacturer.find_by(long_name: manufacturer_data["Name"]) if manufacturer.blank?

      return manufacturer if manufacturer.present?

      Manufacturer.create!(name: manufacturer_data["Name"], code: manufacturer_data["Code"])
    end
  end
end
