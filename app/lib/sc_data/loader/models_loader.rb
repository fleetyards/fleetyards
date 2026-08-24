module ScData
  module Loader
    class ModelsLoader < ::ScData::Loader::BaseLoader
      def all
        update_in_game_flags

        Model.coalescing_broadcasts do
          Model.where(in_game: true).find_each do |model|
            load_model(model)
          end
        end

        Hardpoint.find_each(&:save) # hack to generate correct group_keys
      end

      def one(model)
        update_in_game_flag(model)

        load_model(model.reload)

        model.hardpoints.find_each(&:save) # hack to generate correct group_keys
      end

      def load_model(model)
        model_data = load_model_data(model.sc_data_identifier)

        return if model_data.blank?

        update_loadout(model, model_data)

        model.reload

        ModelPosition.generate_for_model!(model)

        model.set_fuel_consumption_from_hardpoints

        update_params = {}

        update_params = update_metrics(model_data, update_params)
        update_params = update_personal_inventory(model_data, update_params)
        hardpoints = model.hardpoints.game_files
        update_params = update_cargo_holds(hardpoints, update_params)
        update_params = update_quantum_fuel_tanks(hardpoints, update_params)
        update_params = update_hydrogen_fuel_tanks(hardpoints, update_params)
        update_params = update_external_fuel_tanks(hardpoints, update_params)
        update_params = update_refuel_boom(hardpoints, update_params)
        update_params = update_speeds(hardpoints, update_params)
        update_params = update_ground_speeds(model_data, update_params)

        model.update!(update_params.merge(update_reason: :sc_data_loader))
      end

      private def update_in_game_flags
        Model.find_each { |model| update_in_game_flag(model) }
      end

      private def update_in_game_flag(model)
        identifier = model.sc_data_identifier
        return if identifier.blank?

        file_exists = File.exist?(
          Rails.root.join("data/sc_data/parsed/#{sc_environment}/models/#{identifier}.json")
        )

        if file_exists && !model.in_game?
          model.update_columns(in_game: true, production_status: "flight-ready")
        elsif !file_exists && model.in_game?
          model.update_columns(in_game: false)
        end
      end

      private def load_model_data(sc_data_identifier)
        load_item("models/#{sc_data_identifier}")
      end

      private def update_metrics(model_data, update_params)
        update_params[:mass] = model_data.dig("mass")&.to_f
        update_params[:hull_health] = model_data.dig("hull_health")&.to_f
        update_params[:hull_parts] = model_data.dig("hull_parts")
        update_params[:hull_doors] = extract_hull_doors(model_data)
        update_params[:weapon_pool_size] = model_data.dig("weapon_pool_size")
        update_params[:signature_cross_section] = model_data.dig("signature_cross_section")
        update_params[:sc_length] = model_data.dig("metrics", "y")&.to_f
        update_params[:sc_beam] = model_data.dig("metrics", "x")&.to_f
        update_params[:sc_height] = model_data.dig("metrics", "z")&.to_f
        update_params[:ground] = model_data.dig("ground") || false

        update_params
      end

      # The ship's own storage container, which the vehicle entity points at
      # directly rather than hanging off a hardpoint the way cargo grids do.
      private def update_personal_inventory(model_data, update_params)
        ref = model_data["inventory_container_ref"]

        return update_params if ref.blank?

        storage = personal_storage_index[ref]

        return update_params if storage.blank?

        update_params[:personal_inventory] = storage

        update_params
      end

      # Same reason as door_health_index: load_items parses every item file, so
      # index the containers once instead of once per model.
      private def personal_storage_index
        @personal_storage_index ||= load_items("items").each_with_object({}) do |item, index|
          next unless item[:type] == "PersonalStorage"
          next if item[:ref].blank?

          storage = item.dig(:type_data, :storage).to_f
          next unless storage.positive?

          index[item[:ref]] = storage
        end
      end

      # Breakable interior doors, which erkul shows as an area of their own. They
      # are not hull parts: the vehicle XML lists them as `class="ItemPort"`
      # entries, so collect_hull_parts skips them, and their health lives on the
      # door item rather than the geometry. Kept out of hull_health for the same
      # reason erkul separates them — shooting a door does not damage the hull.
      private def extract_hull_doors(model_data)
        doors = (model_data["loadout"] || []).filter_map do |entry|
          health = door_health_index[entry["ref"]] ||
            door_health_index[entry["key"]&.downcase]

          next if health.blank?

          {name: entry["name"], health: health}
        end

        doors.presence
      end

      # load_items globs and parses every item file, so index the doors once
      # rather than looking each one up per model.
      private def door_health_index
        @door_health_index ||= load_items("items").each_with_object({}) do |item, index|
          next unless item[:category] == "doors"

          health = item.dig(:durability, :health).to_f
          next unless health.positive?

          index[item[:ref]] = health if item[:ref].present?
          index[item[:key]&.downcase] = health if item[:key].present?
        end
      end

      private def update_quantum_fuel_tanks(hardpoints, update_params)
        fuel_tanks = extract_type_data(hardpoints, "QuantumFuelTank")

        return update_params if fuel_tanks.blank?

        update_params[:quantum_fuel_tanks] = fuel_tanks

        update_params
      end

      private def update_hydrogen_fuel_tanks(hardpoints, update_params)
        fuel_tanks = extract_type_data(hardpoints, "FuelTank")

        return update_params if fuel_tanks.blank?

        update_params[:hydrogen_fuel_tanks] = fuel_tanks

        update_params
      end

      private def update_external_fuel_tanks(hardpoints, update_params)
        fuel_tanks = extract_named_type_data(hardpoints, "ExternalFuelTank")

        return update_params if fuel_tanks.blank?

        update_params[:external_fuel_tanks] = fuel_tanks

        update_params
      end

      private def update_refuel_boom(hardpoints, update_params)
        boom = extract_refuel_boom(hardpoints)

        return update_params if boom.blank?

        update_params[:refuel_boom] = boom

        update_params
      end

      private def extract_refuel_boom(hardpoints)
        hardpoints.each do |hardpoint|
          next if hardpoint.component&.category != "refuel_boom"
          next if hardpoint.component&.component_type != "ToolArm"

          nozzle = hardpoint.hardpoints.includes(:component).find do |sub|
            sub.component&.component_type == "DockingCollar"
          end

          nozzle_data = nozzle&.component&.type_data || {}

          return {
            "arm_name" => hardpoint.component.name,
            "arm_size" => hardpoint.component.size,
            "nozzle_name" => nozzle&.component&.name,
            "nozzle_size" => nozzle&.component&.size,
            "capture_radius" => nozzle_data["capture_radius"],
            "fuel_flow_rate" => nozzle_data["fuel_flow_rate"],
            "quantum_fuel_flow_rate" => nozzle_data["quantum_fuel_flow_rate"]
          }.compact
        end

        nil
      end

      private def update_speeds(hardpoints, update_params)
        ifcs = extract_type_data(hardpoints, "FlightController")

        ifcs = ifcs.first if ifcs.is_a?(Array)

        return update_params if ifcs.blank?

        update_params[:scm_speed] = ifcs.dig("scm_speed").to_f if ifcs.dig("scm_speed").present?
        update_params[:scm_speed_boosted] = ifcs.dig("scm_speed_boosted").to_f if ifcs.dig("scm_speed_boosted").present?
        update_params[:reverse_speed_boosted] = ifcs.dig("reverse_speed_boosted").to_f if ifcs.dig("reverse_speed_boosted").present?
        update_params[:max_speed] = ifcs.dig("max_speed").to_f if ifcs.dig("max_speed").present?
        update_params[:pitch] = ifcs.dig("angular_velocity", "pitch").to_f if ifcs.dig("angular_velocity", "pitch").present?
        update_params[:pitch_boosted] = ifcs.dig("boosted_angular_velocity", "pitch").to_f if ifcs.dig("boosted_angular_velocity", "pitch").present?
        update_params[:yaw] = ifcs.dig("angular_velocity", "yaw").to_f if ifcs.dig("angular_velocity", "yaw").present?
        update_params[:yaw_boosted] = ifcs.dig("boosted_angular_velocity", "yaw").to_f if ifcs.dig("boosted_angular_velocity", "yaw").present?
        update_params[:roll] = ifcs.dig("angular_velocity", "roll").to_f if ifcs.dig("angular_velocity", "roll").present?
        update_params[:roll_boosted] = ifcs.dig("boosted_angular_velocity", "roll").to_f if ifcs.dig("boosted_angular_velocity", "roll").present?

        update_params
      end

      # Ground vehicles have no FlightController to read speeds off, so the
      # parser takes them straight from the vehicle definition. Only the
      # vehicles that declare a `Handling/Power` block get reverse speed and
      # acceleration; the rest have a top speed and nothing else.
      private def update_ground_speeds(model_data, update_params)
        speeds = model_data.dig("speeds")

        return update_params if speeds.blank?

        update_params[:ground_max_speed] = speeds.dig("max").to_f if speeds.dig("max").present?
        update_params[:ground_reverse_speed] = speeds.dig("reverse").to_f if speeds.dig("reverse").present?
        update_params[:ground_acceleration] = speeds.dig("acceleration").to_f if speeds.dig("acceleration").present?
        update_params[:ground_decceleration] = speeds.dig("decceleration").to_f if speeds.dig("decceleration").present?

        update_params
      end
    end
  end
end
