# frozen_string_literal: true

module Scunpacked
  class Loader
    attr_accessor :base_url

    def initialize
      self.base_url = 'https://scunpacked.com/api'
    end

    CUBIC_METER_TO_SCU_FACTOR = 1.95

    def load_ship(identifier)
      ship_response = fetch_remote("ships/#{identifier.downcase}.json")

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
        quantum_fuel_tanks: extract_quantum_fuel_tanks(components_data)
      }
    end

    def load_item(identifier)
      item_response = fetch_remote("items/#{identifier.downcase}.json")

      return unless item_response.success?

      parse_json_response(item_response)
    end

    private def fetch_remote(path)
      Typhoeus.get("#{base_url}/#{path}")
    end

    private def parse_json_response(response)
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Raven.capture_exception(e)
      Rails.logger.error "SCUnpacked Data could not be parsed: #{response.body}"
      nil
    end

    private def extract_hydrogen_fuel_tanks(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('hardpoint_fuel_tank')
      end.map do |component_ref|
        item_data = load_item(component_ref['entityClassName'])

        {
          name: component_ref['itemPortName'],
          capacity: item_data.dig('Raw', 'Entity', 'Components', 'SCItemFuelTankParams', 'capacity')
        }
      end
    end

    private def extract_quantum_fuel_tanks(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('quantum_fuel_tank')
      end.map do |component_ref|
        item_data = load_item(component_ref['entityClassName'])

        {
          name: component_ref['itemPortName'],
          capacity: item_data.dig('Raw', 'Entity', 'Components', 'SCItemFuelTankParams', 'capacity')
        }
      end
    end

    private def extract_cargo_holds(components)
      components.select do |component_ref|
        component_ref['itemPortName'].include?('cargo')
      end.map do |component_ref|
        item_data = load_item(component_ref['entityClassName'])

        cargo_dimensions = item_data.dig('Raw', 'Entity', 'Components', 'SCItemCargoGridParams', 'dimensions') || {}

        {
          name: component_ref['itemPortName'],
          scu: (cargo_dimensions.values.reject(&:zero?).inject(:*) / CUBIC_METER_TO_SCU_FACTOR).round
        }
      end
    end
  end
end
