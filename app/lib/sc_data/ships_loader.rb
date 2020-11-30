# frozen_string_literal: true

module ScData
  class ShipsLoader < ::ScData::BaseLoader
    CUBIC_METER_TO_SCU_FACTOR = 1.95

    attr_accessor :components_loader

    def initialize
      super

      self.base_url = "#{base_url}/ships"
      self.components_loader = ::ScData::ComponentsLoader.new
    end

    def load(data_slug)
      ship_response = fetch_remote("#{data_slug.downcase}.json")

      return unless ship_response.success?

      ship_data = (parse_json_response(ship_response) || {})['Raw']

      components_data = ship_data.dig(
        'Entity', 'Components', 'SEntityComponentDefaultLoadoutParams', 'loadout',
        'SItemPortLoadoutManualParams', 'entries'
      )

      {
        mass: ((ship_data.dig('Vehicle', 'Parts') || []).first || {})['mass']&.to_f,
        cargo_holds: extract_cargo_holds(components_data),
        hydrogen_fuel_tanks: extract_hydrogen_fuel_tanks(components_data),
        quantum_fuel_tanks: extract_quantum_fuel_tanks(components_data),
        weapons: extract_weapons(components_data),
        turrets: extract_turrets(components_data),
        missiles: extract_missiles(components_data),
      }
    end

    # turrets hardpoint_(.*)_turret
    # missiles hardpoint_missilerack
    # fuel_intakes hardpoint_fuel_intake
    # fuel_tanks hardpoint_fuel_tank
    # quantum_fuel_tanks hardpoint_quantum_fuel_tank
    # quantum_drive hardpoint_quantum_drive
    # jump_modules
    # computers
    # radar hardpoint_radar_scanning
    # main_thrusters hardpoint_thruster_main
    # retro_thruster hardpoint_thruster_retro
    # vtol_thruster hardpoint_thruster_vtol
    # mav_thruster hardpoint_thruster_mav
    # coolers hardpoint_cooler
    # power_plants hardpoint_power_plant
    # shields hardpoint_shield_generator
    # countermeasures hardpoint_countermeasures
    # armor hardpoint_armor


    private def extract_cargo_holds(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('cargo')
      end.map do |component_ref|
        item_data = components_loader.load(component_ref['entityClassName'])

        cargo_dimensions = item_data.dig('Raw', 'Entity', 'Components', 'SCItemCargoGridParams', 'dimensions') || {}

        {
          name: component_ref['itemPortName'],
          scu: (cargo_dimensions.values.reject(&:zero?).inject(:*) / CUBIC_METER_TO_SCU_FACTOR).round,
          dimensions: cargo_dimensions
        }
      end
    end

    private def extract_hydrogen_fuel_tanks(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('hardpoint_fuel_tank')
      end.map do |component_ref|
        item_data = components_loader.load(component_ref['entityClassName'])

        {
          name: component_ref['itemPortName'],
          capacity: item_data.dig('Raw', 'Entity', 'Components', 'SCItemFuelTankParams', 'capacity')
          size:
        }
      end
    end

    private def extract_quantum_fuel_tanks(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('quantum_fuel_tank')
      end.map do |component_ref|
        item_data = components_loader.load(component_ref['entityClassName'])

        {
          name: component_ref['itemPortName'],
          capacity: item_data.dig('Raw', 'Entity', 'Components', 'SCItemFuelTankParams', 'capacity')
          size:
        }
      end
    end
  end
end
