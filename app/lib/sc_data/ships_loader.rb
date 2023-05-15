# frozen_string_literal: true

module ScData
  class ShipsLoader < ::ScData::BaseLoader
    attr_accessor :components_loader, :hardpoints_loader

    def initialize
      super

      self.components_loader = ::ScData::ComponentsLoader.new
      self.hardpoints_loader = ::ScData::HardpointsLoader.new(components_loader:)
    end

    def load(model)
      return if model.sc_identifier.blank?

      ship_data = load_ship_data(model.sc_identifier)

      components_data = load_components_data(model.sc_identifier)

      if components_data.blank?
        Rails.logger.warn "No components data for #{model.sc_identifier}"
        return
      end

      hardpoints_loader.extract_from_components(model, components_data)

      update_params = {
        mass: ship_data["Mass"]&.to_f,
        cargo_holds: extract_cargo_holds(components_data["CargoGrids"]),
        hydrogen_fuel_tanks: extract_hydrogen_fuel_tanks(components_data["HydrogenFuelTanks"]),
        quantum_fuel_tanks: extract_quantum_fuel_tanks(components_data["QuantumFuelTanks"])
      }

      update_params[:beam] = ship_data["Width"]&.to_f if ship_data["Width"]
      update_params[:height] = ship_data["Height"]&.to_f if ship_data["Height"]
      update_params[:length] = ship_data["Length"]&.to_f if ship_data["Length"]
      update_params[:ground] = !ship_data["IsSpaceship"] if ship_data["IsSpaceship"].present?

      Rails.logger.debug update_params.to_yaml
      Rails.logger.debug update_params.inspect

      model.update!(update_params)
    end

    private def load_ship_data(sc_identifier)
      load_from_export("v2/ships/#{sc_identifier.downcase}.json")
    end

    private def load_components_data(sc_identifier)
      load_from_export("v2/ships/#{sc_identifier.downcase}-ports.json")
    end

    private def extract_cargo_holds(cargo_grids = [])
      cargo_grids.filter_map do |cargo_grid|
        installed_item = cargo_grid["InstalledItem"]

        next if installed_item.blank?

        cargo_data = installed_item["CargoGrid"]

        next if cargo_data.blank?

        {
          name: installed_item["Name"],
          scu: cargo_data["Capacity"],
          dimensions: {
            width: cargo_data["Width"],
            height: cargo_data["Height"],
            depth: cargo_data["Depth"]
          }
        }
      end
    end

    private def extract_hydrogen_fuel_tanks(fuel_tanks = [])
      fuel_tanks.filter_map do |fuel_tank|
        installed_item = fuel_tank["InstalledItem"]

        next if installed_item.blank?

        fuel_tank_data = installed_item["HydrogenFuelTank"]

        next if fuel_tank_data.blank?

        {
          name: installed_item["Name"],
          capacity: fuel_tank_data["Capacity"]
        }
      end
    end

    private def extract_quantum_fuel_tanks(fuel_tanks = [])
      fuel_tanks.filter_map do |fuel_tank|
        installed_item = fuel_tank["InstalledItem"]

        next if installed_item.blank?

        fuel_tank_data = installed_item["QuantumFuelTank"]

        next if fuel_tank_data.blank?

        {
          name: installed_item["Name"],
          capacity: fuel_tank_data["Capacity"]
        }
      end
    end
  end
end
