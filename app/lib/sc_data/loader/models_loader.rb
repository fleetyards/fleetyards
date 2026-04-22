module ScData
  module Loader
    class ModelsLoader < ::ScData::Loader::BaseLoader
      def all
        update_in_game_flags

        Model.where(in_game: true).find_each do |model|
          load_model(model)
        end

        Hardpoint.find_each(&:save) # hack to generate correct group_keys
      end

      def one(model)
        load_model(model)

        model.hardpoints.find_each(&:save) # hack to generate correct group_keys
      end

      def load_model(model)
        model_data = load_model_data(model.sc_data_identifier)

        return if model_data.blank?

        update_loadout(model, model_data)

        model.reload

        model.set_fuel_consumption_from_hardpoints

        update_params = {}

        update_params = update_metrics(model_data, update_params)
        hardpoints = model.hardpoints.game_files
        update_params = update_cargo_holds(hardpoints, update_params)
        update_params = update_quantum_fuel_tanks(hardpoints, update_params)
        update_params = update_hydrogen_fuel_tanks(hardpoints, update_params)
        update_params = update_speeds(hardpoints, update_params)

        model.update!(update_params.merge(update_reason: :sc_data_loader))
      end

      private def update_in_game_flags
        Model.find_each do |model|
          identifier = model.sc_data_identifier
          next if identifier.blank?

          file_exists = File.exist?(
            Rails.root.join("data/sc_data/parsed/#{sc_environment}/models/#{identifier}.json")
          )

          if file_exists && !model.in_game?
            model.update_columns(in_game: true, production_status: "flight-ready")
          elsif !file_exists && model.in_game?
            model.update_columns(in_game: false)
          end
        end
      end

      private def load_model_data(sc_data_identifier)
        load_item("models/#{sc_data_identifier}")
      end

      private def update_metrics(model_data, update_params)
        update_params[:mass] = model_data.dig("mass")&.to_f
        update_params[:sc_length] = model_data.dig("metrics", "y")&.to_f
        update_params[:sc_beam] = model_data.dig("metrics", "x")&.to_f
        update_params[:sc_height] = model_data.dig("metrics", "z")&.to_f
        update_params[:ground] = model_data.dig("ground") || false

        update_params
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
    end
  end
end
