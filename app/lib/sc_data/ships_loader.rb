# frozen_string_literal: true

module ScData
  class ShipsLoader < ::ScData::BaseLoader
    attr_accessor :components_loader, :hardpoints_loader

    def initialize
      super

      self.base_url = "#{base_url}/ships"
      self.components_loader = ::ScData::ComponentsLoader.new
      self.hardpoints_loader = ::ScData::HardpointsLoader.new(components_loader: components_loader)
    end

    def load(model)
      return if model.sc_identifier.blank?

      sleep 1

      ship_response = fetch_remote("#{model.sc_identifier.downcase}.json")

      return unless ship_response.success?

      ship_data = (parse_json_response(ship_response) || {})

      sleep 1

      ports_response = fetch_remote("#{model.sc_identifier.downcase}-ports.json")

      return unless ports_response.success?

      components_data = (parse_json_response(ports_response) || {})

      hardpoints_loader.extract_from_components(model, components_data)

      model.update!(
        mass: ship_data['Mass']&.to_f,
        cargo_holds: extract_cargo_holds(components_data['CargoGrids']),
        hydrogen_fuel_tanks: extract_hydrogen_fuel_tanks(components_data['HydrogenFuelTanks']),
        quantum_fuel_tanks: extract_quantum_fuel_tanks(components_data['QuantumFuelTanks'])
      )
    end

    private def extract_cargo_holds(cargo_grids = [])
      cargo_grids.filter_map do |cargo_grid|
        installed_item = cargo_grid['InstalledItem']

        next if installed_item.blank?

        cargo_data = installed_item['CargoGrid']

        next if cargo_data.blank?

        {
          name: installed_item['Name'],
          scu: cargo_data['Capacity'],
          dimensions: {
            width: cargo_data['Width'],
            height: cargo_data['Height'],
            depth: cargo_data['Depth']
          }
        }
      end
    end

    private def extract_hydrogen_fuel_tanks(fuel_tanks = [])
      fuel_tanks.filter_map do |fuel_tank|
        installed_item = fuel_tank['InstalledItem']

        next if installed_item.blank?

        fuel_tank_data = installed_item['HydrogenFuelTank']

        next if fuel_tank_data.blank?

        {
          name: installed_item['Name'],
          capacity: fuel_tank_data['Capacity']
        }
      end
    end

    private def extract_quantum_fuel_tanks(fuel_tanks = [])
      fuel_tanks.filter_map do |fuel_tank|
        installed_item = fuel_tank['InstalledItem']

        next if installed_item.blank?

        fuel_tank_data = installed_item['QuantumFuelTank']

        next if fuel_tank_data.blank?

        {
          name: installed_item['Name'],
          capacity: fuel_tank_data['Capacity']
        }
      end
    end
  end
end
