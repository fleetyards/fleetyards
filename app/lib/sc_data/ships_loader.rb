# frozen_string_literal: true

module ScData
  class ShipsLoader < ::ScData::BaseLoader
    CUBIC_METER_TO_SCU_FACTOR = 1.95

    HARDPOINT_TYPES = %w[
      quantum_drives maneuvering_thrusters power_plants
      main_thrusters coolers shield_generators weapons turrets missiles
    ].freeze

    attr_accessor :components_loader

    def initialize
      super

      self.base_url = "#{base_url}/ships"
      self.components_loader = ::ScData::ComponentsLoader.new
    end

    def load(model)
      return if model.sc_identifier.blank?

      ship_response = fetch_remote("#{model.sc_identifier.downcase}.json")

      return unless ship_response.success?

      ship_data = (parse_json_response(ship_response) || {})['Raw']

      components_data = ship_data.dig(
        'Entity', 'Components', 'SEntityComponentDefaultLoadoutParams', 'loadout',
        'SItemPortLoadoutManualParams', 'entries'
      )

      add_hardpoints(model, components_data)

      model.update({
                     mass: ((ship_data.dig('Vehicle', 'Parts') || []).first || {})['mass']&.to_f,
                     cargo_holds: extract_cargo_holds(components_data),
                     hydrogen_fuel_tanks: extract_hydrogen_fuel_tanks(components_data),
                     quantum_fuel_tanks: extract_quantum_fuel_tanks(components_data),
                   })
    end

    def add_hardpoints(model, components_data); end

    # scunpacked

    # weapons hardpoint_weapon
    # turrets hardpoint_(.*)_turret
    # missiles hardpoint_missilerack

    # fuel_intakes hardpoint_fuel_intake

    # quantum_drive hardpoint_quantum_drive

    # main_thrusters hardpoint_thruster_main
    # retro_thruster hardpoint_thruster_retro
    # vtol_thruster hardpoint_thruster_vtol
    # mav_thruster hardpoint_thruster_mav

    # coolers hardpoint_cooler

    # power_plants hardpoint_power_plant

    # shields hardpoint_shield_generator

    # countermeasures hardpoint_countermeasures

    # armor hardpoint_armor

    private def extract_base_component_data(component_data)
      base_data = component_data.dig('SAttachableComponentParams', 'AttachDef')

      {
        size: base_data['size'],
        grade: base_data['grade']
      }
    end

    private def extract_cargo_holds(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('cargo')
      end.map do |component_ref|
        item_data = components_loader.load(component_ref['entityClassName'])

        component_data = item_data.dig('Raw', 'Entity', 'Components')

        cargo_dimensions = component_data.dig('SCItemCargoGridParams', 'dimensions') || {}

        {
          name: component_ref['itemPortName'],
          scu: (cargo_dimensions.values.reject(&:zero?).inject(:*) / CUBIC_METER_TO_SCU_FACTOR).round,
          dimensions: cargo_dimensions,
        }.merge(extract_base_component_data(component_data))
      end
    end

    private def extract_hydrogen_fuel_tanks(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('hardpoint_fuel_tank')
      end.map do |component_ref|
        item_data = components_loader.load(component_ref['entityClassName'])

        component_data = item_data.dig('Raw', 'Entity', 'Components')

        {
          name: component_ref['itemPortName'],
        }.merge(extract_fuel_data(component_data))
          .merge(extract_base_component_data(component_data))
      end
    end

    private def extract_quantum_fuel_tanks(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('quantum_fuel_tank')
      end.map do |component_ref|
        item_data = components_loader.load(component_ref['entityClassName'])

        component_data = item_data.dig('Raw', 'Entity', 'Components')

        {
          name: component_ref['itemPortName'],
        }.merge(extract_fuel_data(component_data))
          .merge(extract_base_component_data(component_data))
      end
    end

    private def extract_fuel_data(component_data)
      fuel_data = component_data['SCItemFuelTankParams']

      {
        capacity: fuel_data['capacity'],
        fill_rate: fuel_data['fillRate'],
        drain_rate: fuel_data['drainRate']
      }
    end
  end
end
