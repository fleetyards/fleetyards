# frozen_string_literal: true

module ScData
  class ShipsLoader < ::ScData::BaseLoader
    CUBIC_METER_TO_SCU_FACTOR = 1.95

    HARDPOINT_TYPES = %w[
      quantum_drives maneuvering_thrusters power_plants
      main_thrusters coolers shield_generators weapons turrets missiles
    ].freeze

    attr_accessor :components_loader, :hardpoints_loader

    def initialize
      super

      self.base_url = "#{base_url}/ships"
      self.components_loader = ::ScData::ComponentsLoader.new
      self.hardpoints_loader = ::ScData::HardpointsLoader.new(components_loader: components_loader)
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

      hardpoints_loader.load(model, components_data)

      model.update({
                     mass: ((ship_data.dig('Vehicle', 'Parts') || []).first || {})['mass']&.to_f,
                     cargo_holds: extract_cargo_holds(components_data),
                     hydrogen_fuel_tanks: extract_hydrogen_fuel_tanks(components_data),
                     quantum_fuel_tanks: extract_quantum_fuel_tanks(components_data),
                   })
    end

    private def extract_cargo_holds(components)
      components.select do |component_ref|
        component_ref['itemPortName'].downcase.include?('cargo')
      end.filter_map do |component_ref|
        component_data = components_loader.load(component_ref['entityClassName'])

        next if component_data.blank?

        cargo_dimensions = component_data.dig(:component, 'SCItemCargoGridParams', 'dimensions') || {}

        next if cargo_dimensions.blank?

        {
          name: component_ref['itemPortName'],
          scu: (cargo_dimensions.values.reject(&:zero?).inject(:*) / CUBIC_METER_TO_SCU_FACTOR).round,
          dimensions: cargo_dimensions,
        }.merge(component_data[:base])
      end
    end

    private def extract_hydrogen_fuel_tanks(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('hardpoint_fuel_tank')
      end.map do |component_ref|
        component_data = components_loader.load(component_ref['entityClassName'])

        {
          name: component_ref['itemPortName'],
        }.merge(extract_fuel_data(component_data))
          .merge(component_data[:base])
      end
    end

    private def extract_quantum_fuel_tanks(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('quantum_fuel')
      end.map do |component_ref|
        component_data = components_loader.load(component_ref['entityClassName'])

        {
          name: component_ref['itemPortName'],
        }.merge(extract_fuel_data(component_data))
          .merge(component_data[:base])
      end
    end

    private def extract_fuel_data(component_data)
      fuel_data = component_data.dig(:component, 'SCItemFuelTankParams')

      {
        capacity: fuel_data['capacity'],
        fill_rate: fuel_data['fillRate'],
        drain_rate: fuel_data['drainRate']
      }
    end
  end
end
