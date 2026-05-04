module ScData
  module Parser
    class ModelsParser < ::ScData::Parser::BaseParser
      def all
        parse_ships
        parse_vehicles
        parse_powersuits
      end

      private def parse_ships
        ships = load_data("entities/spaceships").filter_map do |item|
          key = item[:key]
          values = item[:values]

          loadout = (values.dig(
            "Components",
            "SEntityComponentDefaultLoadoutParams",
            "loadout",
            "SItemPortLoadoutManualParams",
            "entries",
            "SItemPortLoadoutEntryParams"
          ) || []).filter_map do |item|
            extract_loadout(item)
          end

          loadout = merge_module_ports(values, loadout)

          {
            key:,
            ground: false,
            movement_class: values.dig("Components", "VehicleComponentParams", "movementClass"),
            gravlev: values.dig("Components", "VehicleComponentParams", "isGravlevVehicle"),
            min_crew: values.dig("Components", "VehicleComponentParams", "crewSize"),
            name: translate(values.dig("Components", "VehicleComponentParams", "vehicleName")),
            description: translate(values.dig("Components", "VehicleComponentParams", "vehicleDescription")),
            career: translate(values.dig("Components", "VehicleComponentParams", "vehicleCareer")),
            role: translate(values.dig("Components", "VehicleComponentParams", "vehicleRole")),
            insurance: {
              base_wait_time_minutes: values.dig("StaticEntityClassData", "SEntityInsuranceProperties", "shipInsuranceParams", "baseWaitTimeMinutes"),
              mandatory_wait_time_minutes: values.dig("StaticEntityClassData", "SEntityInsuranceProperties", "shipInsuranceParams", "mandatoryWaitTimeMinutes"),
              base_expediting_fee: values.dig("StaticEntityClassData", "SEntityInsuranceProperties", "shipInsuranceParams", "baseExpeditingFee")
            },
            mass: extract_mass(values.dig("Components", "VehicleComponentParams")),
            metrics: {
              x: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "x").to_f,
              y: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "y").to_f,
              z: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "z").to_f
            },
            loadout:
          }
        end

        save_items(ships, folder: "models")
      end

      private def parse_vehicles
        vehicles = load_data("entities/groundvehicles").filter_map do |item|
          key = item[:key]
          values = item[:values]

          loadout = (values.dig(
            "Components",
            "SEntityComponentDefaultLoadoutParams",
            "loadout",
            "SItemPortLoadoutManualParams",
            "entries",
            "SItemPortLoadoutEntryParams"
          ) || []).filter_map do |item|
            extract_loadout(item)
          end

          loadout = merge_module_ports(values, loadout)

          insurance = values.dig("StaticEntityClassData", "SEntityInsuranceProperties")

          if insurance.is_a?(Array)
            insurance = insurance.last
          end

          {
            key:,
            ground: true,
            movement_class: values.dig("Components", "VehicleComponentParams", "movementClass"),
            gravlev: values.dig("Components", "VehicleComponentParams", "isGravlevVehicle"),
            min_crew: values.dig("Components", "VehicleComponentParams", "crewSize"),
            name: translate(values.dig("Components", "VehicleComponentParams", "vehicleName")),
            description: translate(values.dig("Components", "VehicleComponentParams", "vehicleDescription")),
            career: translate(values.dig("Components", "VehicleComponentParams", "vehicleCareer")),
            role: translate(values.dig("Components", "VehicleComponentParams", "vehicleRole")),
            insurance: {
              base_wait_time_minutes: insurance.dig("shipInsuranceParams", "baseWaitTimeMinutes"),
              mandatory_wait_time_minutes: insurance.dig("shipInsuranceParams", "mandatoryWaitTimeMinutes"),
              base_expediting_fee: insurance.dig("shipInsuranceParams", "baseExpeditingFee")
            },
            mass: extract_mass(values.dig("Components", "VehicleComponentParams")),
            metrics: {
              x: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "x").to_f,
              y: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "y").to_f,
              z: values.dig("Components", "VehicleComponentParams", "maxBoundingBoxSize", "z").to_f
            },
            loadout:
          }
        end

        save_items(vehicles, folder: "models")
      end

      private def parse_powersuits
        powersuits = load_data("actor/actors").filter_map do |item|
          key = item[:key]
          values = item[:values]

          actor_params = values.dig("Components", "SActorComponentParams")
          next unless actor_params&.dig("actorType") == "Transport"

          display_params = values.dig("StaticEntityClassData", "SEntityInsuranceProperties", "displayParams")
          name_key = display_params&.dig("name")
          next if name_key.blank? || name_key == "@LOC_UNINITIALIZED"

          loadout = (values.dig(
            "Components",
            "SEntityComponentDefaultLoadoutParams",
            "loadout",
            "SItemPortLoadoutManualParams",
            "entries",
            "SItemPortLoadoutEntryParams"
          ) || []).filter_map do |entry|
            extract_loadout(entry)
          end

          loadout = merge_module_ports(values, loadout)

          insurance_params = values.dig("StaticEntityClassData", "SEntityInsuranceProperties", "shipInsuranceParams")

          {
            key:,
            ground: true,
            movement_class: nil,
            gravlev: nil,
            min_crew: display_params&.dig("crewSize"),
            name: translate(name_key),
            description: nil,
            career: translate(display_params&.dig("career")),
            role: translate(display_params&.dig("role")),
            insurance: {
              base_wait_time_minutes: insurance_params&.dig("baseWaitTimeMinutes"),
              mandatory_wait_time_minutes: insurance_params&.dig("mandatoryWaitTimeMinutes"),
              base_expediting_fee: insurance_params&.dig("baseExpeditingFee")
            },
            mass: values.dig("Components", "SSCActorPhysicsControllerComponentParams", "physType", "SEntityActorPhysicsControllerParams", "Mass")&.to_f,
            metrics: {x: 0.0, y: 0.0, z: 0.0},
            loadout:
          }
        end

        save_items(powersuits, folder: "models")
      end

      private def merge_module_ports(values, loadout)
        port_defs = values.dig(
          "Components",
          "SItemPortContainerComponentParams",
          "Ports",
          "SItemPortDef"
        )

        return loadout if port_defs.blank?

        port_defs = [port_defs] unless port_defs.is_a?(Array)
        loadout_names = loadout.map { |entry| entry[:name] }.to_set

        port_defs.each do |port|
          name = port["Name"]
          next if name.blank?
          next if loadout_names.include?(name)

          types = port.dig("Types", "SItemPortDefTypes")
          types = [types] unless types.is_a?(Array)
          next unless types.compact.any? { |t| t["Type"] == "Module" }

          loadout << {
            name:,
            ref: nil,
            key: nil
          }
        end

        loadout
      end

      private def extract_loadout(item)
        name = item.dig("itemPortName")

        return if blacklisted_item_key?(name)

        ref = item.dig("entityClassReference")
        ref = nil if ref == "00000000-0000-0000-0000-000000000000" || ref.blank?
        key = item.dig("entityClassName")
        key = nil if key.blank?

        data = {
          name:,
          ref:,
          key:
        }

        loadout = ((item.dig("loadout").is_a?(String) ? {} : item.dig("loadout")) || {}).dig(
          "SItemPortLoadoutManualParams",
          "entries",
          "SItemPortLoadoutEntryParams"
        ) || []
        unless loadout.is_a?(Array)
          loadout = [loadout]
        end

        if loadout.present?
          data[:loadout] = loadout.filter_map do |item|
            extract_loadout(item)
          end
        end

        data
      end

      private def extract_mass(component_params)
        definition_file_path = component_params.dig("vehicleDefinition")

        return if definition_file_path.blank?

        modification_key = component_params.dig("modification")

        definition_data = Hash.from_xml(File.read("#{definition_path}/#{definition_file_path}"))

        definition_data = extract_modification_definition(definition_data, modification_key)

        definition_data.dig("Vehicle", "Parts", "Part", "mass")&.to_f
      end

      private def extract_modification_definition(definition_data, modification_key)
        if modification_key.blank?
          return definition_data
        end

        modification = if definition_data.dig("Vehicle", "Modifications", "Modification").is_a?(Array)
          definition_data.dig("Vehicle", "Modifications", "Modification").find do |modification|
            modification.dig("name") == modification_key
          end
        elsif definition_data.dig("Vehicle", "Modifications", "Modification", "name") == modification_key
          definition_data.dig("Vehicle", "Modifications", "Modification")
        end

        if modification.blank?
          return definition_data
        end

        vehicle_modification = if modification.dig("Elems", "Elem").is_a?(Array)
          modification.dig("Elems", "Elem").find do |elem|
            elem.dig("idRef") == definition_data.dig("Vehicle", "id")
          end
        elsif modification.dig("Elems", "Elem", "idRef") == definition_data.dig("Vehicle", "id")
          modification.dig("Elems", "Elem")
        end

        if vehicle_modification.present?
          definition_data["Vehicle"][vehicle_modification.dig("name")] = vehicle_modification.dig("value")
        end

        main_part = definition_data.dig("Vehicle", "Parts", "Part")
        main_part_modification = if modification.dig("Elems", "Elem").is_a?(Array)
          modification.dig("Elems", "Elem").find do |elem|
            elem.dig("idRef") == main_part.dig("id")
          end
        elsif modification.dig("Elems", "Elem", "idRef") == main_part.dig("id")
          modification.dig("Elems", "Elem")
        end

        if main_part_modification.present?
          definition_data["Vehicle"]["Parts"]["Part"][main_part_modification.dig("name")] = main_part_modification.dig("value")
        end

        definition_data
      end
    end
  end
end
