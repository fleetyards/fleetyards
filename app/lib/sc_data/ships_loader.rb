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

      update_params = extract_metrics(ship_data, components_data)
      update_params = extract_speeds(ship_data, update_params)

      model.update!(update_params.merge(update_reason: :sc_loader))
    end

    private def extract_metrics(ship_data, components_data)
      update_params = {
        mass: ship_data["Mass"]&.to_f,
        cargo_holds: extract_cargo_holds(components_data["CargoGrids"]),
        hydrogen_fuel_tanks: extract_hydrogen_fuel_tanks(components_data["HydrogenFuelTanks"]),
        quantum_fuel_tanks: extract_quantum_fuel_tanks(components_data["QuantumFuelTanks"])
      }

      update_params[:sc_beam] = ship_data["Width"]&.to_f if ship_data["Width"]
      update_params[:sc_height] = ship_data["Height"]&.to_f if ship_data["Height"]
      update_params[:sc_length] = ship_data["Length"]&.to_f if ship_data["Length"]
      update_params[:ground] = ship_data["IsVehicle"] if ship_data["IsVehicle"].present?

      update_params
    end

    private def extract_speeds(ship_data, update_params)
      flight_speeds = ship_data["FlightCharacteristics"] || {}
      if flight_speeds.present?
        update_params[:scm_speed] = flight_speeds["ScmSpeed"]&.to_f if flight_speeds["ScmSpeed"].present?
        update_params[:max_speed] = flight_speeds["MaxSpeed"]&.to_f if flight_speeds["MaxSpeed"].present?
        update_params[:scm_speed_acceleration] = flight_speeds["ZeroToScm"]&.to_f if flight_speeds["ZeroToScm"].present?
        update_params[:scm_speed_decceleration] = flight_speeds["ScmToZero"]&.to_f if flight_speeds["ScmToZero"].present?
        update_params[:max_speed_acceleration] = flight_speeds["ZeroToMax"]&.to_f if flight_speeds["ZeroToMax"].present?
        update_params[:max_speed_decceleration] = flight_speeds["MaxToZero"]&.to_f if flight_speeds["MaxToZero"].present?
        update_params[:pitch] = flight_speeds["Pitch"]&.to_f if flight_speeds["Pitch"].present?
        update_params[:yaw] = flight_speeds["Yaw"]&.to_f if flight_speeds["Yaw"].present?
        update_params[:roll] = flight_speeds["Roll"]&.to_f if flight_speeds["Roll"].present?
      end

      ground_speeds = ship_data["DriveCharacteristics"] || {}
      if ground_speeds.present?
        update_params[:ground_max_speed] = ground_speeds["TopSpeed"]&.to_f if ground_speeds["TopSpeed"].present?
        update_params[:ground_reverse_speed] = ground_speeds["ReverseSpeed"]&.to_f if ground_speeds["ReverseSpeed"].present?
        update_params[:ground_acceleration] = ground_speeds["Acceleration"]&.to_f if ground_speeds["Acceleration"].present?
        update_params[:ground_decceleration] = ground_speeds["Decceleration"]&.to_f if ground_speeds["Decceleration"].present?
      end

      update_params
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
