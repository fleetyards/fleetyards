module ScData
  module Loader
    class ModelsLoader < ::ScData::Loader::BaseLoader
      # Which axis of the export's bounding box is the length, the beam and the
      # height. `maxBoundingBoxSize` in the entity record carries three correct
      # magnitudes but no consistent convention for which is which -- it depends on
      # how the model was authored -- so the default below is wrong for a handful
      # of ships. Measured over 1031 ship entities, its largest value sits on `y`
      # for 829, on `x` for 174 and on `z` for 28.
      #
      # It cannot be derived from the export: item-port positions give a reliable
      # forward axis but do not share the bounding box's frame, the signature
      # cross-section correlates with nothing, and the meshes that would settle it
      # are assembled from dozens of parts and are not exported at all.
      #
      # So it is curated, and read off the orthographic renders instead. Those
      # share their edges -- from above a ship is length x beam, from the side
      # length x height -- which both validates the crop and gives the true
      # proportions. Each entry below is the permutation whose proportions match
      # the render; the ship matrix plays no part, which matters because it is
      # itself wrong for several of them.
      #
      # A permutation reflects how the model was authored, so it holds across
      # patches while the measurements keep coming from the game files. Ships not
      # listed use the default.
      AXIS_ORDER = {
        "drak_caterpillar" => %i[z x y],
        "crus_starlifter_m2" => %i[x y z],
        "crus_starlifter_a2" => %i[x y z],
        "crus_starlifter_c2" => %i[x y z],
        "crus_star_runner" => %i[x y z],
        "gama_tyilui" => %i[x y z],
        "rsi_scorpius" => %i[x y z],
        "rsi_scorpius_antares" => %i[x y z],
        "rsi_hermes" => %i[x y z],
        "tmbl_cyclone" => %i[x y z],
        "tmbl_storm_aa" => %i[x y z]
      }.freeze

      DEFAULT_AXIS_ORDER = %i[y x z].freeze

      def all
        loaded = []

        # Every model whose file this build ships, asked of the tree rather than
        # of a stored flag: writing that flag is what made "is it in the game"
        # answerable only for whichever environment loaded last.
        Model.find_each do |model|
          next unless parsed?(model)

          loaded << model.id if load_model(model)
        end

        # A model the export dropped loses its current build and keeps the row --
        # which is now also what makes `in_game?` false for it. A hangar entry
        # pointing at a retired ship still has to resolve, so the row stays.
        retire_absent_builds(ModelBuild, :model_id, loaded)

        prune_builds(ModelBuild)

        Hardpoint.find_each(&:save) # hack to generate correct group_keys
      end

      def one(model)
        load_model(model.reload)

        model.hardpoints.find_each(&:save) # hack to generate correct group_keys
      end

      def load_model(model)
        model_data = load_model_data(model.sc_data_identifier)

        return if model_data.blank?

        update_loadout(model, model_data)

        model.reload

        ModelPosition.generate_for_model!(model)

        update_params = {}

        # Computed here because they read the loadout `update_loadout` just wrote.
        update_params[:fuel_consumption] = model.fuel_consumption_from_hardpoints
        update_params.merge!(model.accelerations_from_hardpoints)

        update_params = update_metrics(model, model_data, update_params)
        update_params = update_personal_inventory(model_data, update_params)
        hardpoints = model.hardpoints.game_files
        update_params = update_cargo_holds(hardpoints, update_params)
        update_params = update_quantum_fuel_tanks(hardpoints, update_params)
        update_params = update_hydrogen_fuel_tanks(hardpoints, update_params)
        update_params = update_external_fuel_tanks(hardpoints, update_params)
        update_params = update_refuel_boom(hardpoints, update_params)
        update_params = update_speeds(hardpoints, update_params)
        update_params = update_ground_speeds(model_data, update_params)

        # A ship the build ships is flying, and this is where that used to be
        # recorded -- alongside the flag, on the transition into the game. The
        # transition is now "it had no build for this source before this load",
        # which is the same moment said in terms of what is actually true.
        update_params[:production_status] = "flight-ready" if model.build.blank?

        apply(model, update_params.merge(update_reason: :sc_data_loader))

        # Dual-write. Built from `update_params` before the reason is merged in:
        # `update_reason` is an `attr_accessor` on Model for paper_trail's meta,
        # not a column, so it has nowhere to land here.
        build = apply_build(model, update_params.slice(*ModelBuild::FACTS))

        # Recorded now because the build it is measured against is pruned after
        # three patches. Waiting until someone asks means there is nothing left
        # to compare.
        ModelBuildChange.record!(build)

        build
      end

      # Whether this build ships a file for the model, which is what a build row
      # comes to express once one is written.
      private def parsed?(model)
        identifier = model.sc_data_identifier
        return false if identifier.blank?

        export_path.join("models", "#{identifier}.json").exist?
      end

      private def load_model_data(sc_data_identifier)
        load_item("models/#{sc_data_identifier}")
      end

      private def update_metrics(model, model_data, update_params)
        update_params[:mass] = model_data.dig("mass")&.to_f
        update_params[:hull_health] = model_data.dig("hull_health")&.to_f
        update_params[:hull_parts] = model_data.dig("hull_parts")
        update_params[:hull_doors] = extract_hull_doors(model_data)
        update_params[:weapon_pool_size] = model_data.dig("weapon_pool_size")
        update_params[:signature_cross_section] = model_data.dig("signature_cross_section")
        update_params.merge!(dimensions(model, model_data))
        update_params[:ground] = model_data.dig("ground") || false

        update_params
      end

      private def dimensions(model, model_data)
        order = AXIS_ORDER.fetch(model.sc_data_identifier, DEFAULT_AXIS_ORDER)
        metrics = model_data["metrics"] || {}

        {
          sc_length: metrics[order[0].to_s]&.to_f,
          sc_beam: metrics[order[1].to_s]&.to_f,
          sc_height: metrics[order[2].to_s]&.to_f
        }
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
