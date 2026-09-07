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

          loadout = merge_port_defs(values, loadout)

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
            inventory_container_ref: value_or_nil(values.dig("Components", "VehicleComponentParams", "inventoryContainerParams")),
            weapon_pool_size: extract_weapon_pool_size(values),
            signature_cross_section: extract_cross_section(values),
            **extract_hull(values.dig("Components", "VehicleComponentParams")),
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

          loadout = merge_port_defs(values, loadout)

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
            inventory_container_ref: value_or_nil(values.dig("Components", "VehicleComponentParams", "inventoryContainerParams")),
            **extract_hull(values.dig("Components", "VehicleComponentParams")),
            speeds: extract_ground_speeds(values.dig("Components", "VehicleComponentParams")),
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

          loadout = merge_port_defs(values, loadout)

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

      # A port declares what may sit in it -- the item types it accepts and the
      # size range it takes -- and none of that is derivable from whatever the
      # default loadout happens to have installed. The Retaliator's ordnance bay
      # takes an S3-S9 missile, bomb or gun launcher; all the loadout says is
      # that an S9 torpedo rack is in it today.
      #
      # A port that accepts a module is also appended when the loadout leaves it
      # empty, since an empty module slot is still a slot.
      private def merge_port_defs(values, loadout)
        record_port_defs = extract_port_defs(values)
        port_defs = extract_definition_port_defs(values.dig("Components", "VehicleComponentParams"))
          .merge(record_port_defs)

        return loadout if port_defs.blank?

        merged = loadout.map do |entry|
          port_def = port_defs[entry[:name]]

          port_def.present? ? entry.merge(port_def) : entry
        end

        merged_names = merged.map { |entry| entry[:name] }.to_set

        # Appended from the entity record alone, which is the set that was
        # appended before reading the definition at all. The definition also
        # calls the Hornet's configurable centre mount module-capable, and
        # appending that would hand the Super Hornet a module slot it has never
        # had -- a change to what the ship offers, not to what a port declares.
        record_port_defs.each do |name, port_def|
          next if merged_names.include?(name)
          next unless port_def[:types].include?("Module")

          merged << {name:, ref: nil, key: nil, **port_def}
        end

        merged
      end

      private def extract_port_defs(values)
        port_defs = values.dig(
          "Components",
          "SItemPortContainerComponentParams",
          "Ports",
          "SItemPortDef"
        )

        return {} if port_defs.blank?

        port_defs = [port_defs] unless port_defs.is_a?(Array)

        port_defs.each_with_object({}) do |port, index|
          name = port["Name"]
          next if name.blank?

          index[name] ||= {
            min_size: port["MinSize"],
            max_size: port["MaxSize"],
            types: extract_port_def_types(port)
          }
        end
      end

      private def extract_port_def_types(port)
        types = port.dig("Types", "SItemPortDefTypes")
        types = [types] unless types.is_a?(Array)

        types.compact.filter_map { |type| type["Type"] }
      end

      # A ship's item ports are declared in its vehicle implementation XML. The
      # entity record's own `Ports` block only adds a handful of late ones (life
      # support, the relay), so both are needed: the Eclipse's torpedo rack port
      # -- the one that takes a bomb rack just as happily -- exists only here.
      private def extract_definition_port_defs(component_params)
        definition_file_path = component_params&.dig("vehicleDefinition")

        return {} if definition_file_path.blank?

        definition_file = "#{definition_path}/#{definition_file_path}"

        return {} unless File.exist?(definition_file)

        definition_data = extract_modification_definition(
          Hash.from_xml(File.read(definition_file)),
          component_params.dig("modification")
        )

        collect_item_ports(definition_data.dig("Vehicle", "Parts", "Part"))
      end

      # The same nested part tree `collect_hull_parts` walks, keeping exactly the
      # parts it throws away.
      private def collect_item_ports(node, ports = {})
        case node
        when Array
          node.each { |value| collect_item_ports(value, ports) }
        when Hash
          item_port = node["ItemPort"]

          if node["name"].present? && node["class"] == "ItemPort" && item_port.is_a?(Hash)
            ports[node["name"]] ||= {
              min_size: item_port["minSize"],
              max_size: item_port["maxSize"],
              types: extract_item_port_types(item_port)
            }
          end

          collect_item_ports(node.dig("Parts", "Part"), ports)
        end

        ports
      end

      # A handful of ports carry junk where their types should be -- the
      # Reclaimer's shield mounts hold a stray backtick -- so the block is only
      # read when it came through as one.
      private def extract_item_port_types(item_port)
        types = item_port["Types"]

        return [] unless types.is_a?(Hash)

        Array.wrap(types["Type"]).filter_map do |type|
          type["type"] if type.is_a?(Hash)
        end
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

      # Hull health comes from the vehicle implementation XML's part tree. Each
      # structural part carries a `damageMax`; the ItemPort parts (weapon/thruster
      # mounts) are excluded, matching the hull HP erkul.games reports. Returns the
      # per-part breakdown and their sum.
      private def extract_hull(component_params)
        definition_file_path = component_params.dig("vehicleDefinition")

        return {} if definition_file_path.blank?

        modification_key = component_params.dig("modification")

        definition_data = Hash.from_xml(File.read("#{definition_path}/#{definition_file_path}"))

        definition_data = extract_modification_definition(definition_data, modification_key)

        parts = collect_hull_parts(definition_data.dig("Vehicle", "Parts", "Part"))

        return {} if parts.blank?

        {
          hull_health: parts.sum { |part| part[:health] },
          hull_parts: parts
        }
      end

      # Ground vehicles carry no flight controller, so their speeds come from the
      # implementation XML's `MovementParams` rather than an IFCS item. Two
      # independent limits live there and only around half the vehicles have the
      # first one: `Handling/Power` is the arcade controller's target speed, while
      # `wWheelsMax` caps how fast physics may spin the driven wheels. Whichever
      # is lower is the speed the vehicle actually reaches.
      private def extract_ground_speeds(component_params)
        definition_file_path = component_params.dig("vehicleDefinition")

        return {} if definition_file_path.blank?

        definition_data = Hash.from_xml(File.read("#{definition_path}/#{definition_file_path}"))

        movement = extract_movement_params(definition_data, definition_file_path, component_params.dig("modification"))

        return {} if movement.blank?

        power = extract_handling_power(movement)
        target_speed = power&.dig("topSpeed")&.to_f || movement.dig("TrackWheeled", "maxSpeed")&.to_f
        wheel_speed = extract_wheel_speed_limit(movement, definition_data)

        return {} if target_speed.blank? && wheel_speed.blank?

        {
          max: [target_speed, wheel_speed].compact.min,
          reverse: power&.dig("reverseSpeed")&.to_f,
          acceleration: power&.dig("acceleration")&.to_f,
          decceleration: power&.dig("decceleration")&.to_f
        }
      end

      # Variants replace the whole `MovementParams` block through their
      # modification's `patchFile` — the inline `Elems` overrides that
      # extract_modification_definition applies only carry display names and
      # masses. The Cyclone tunes every variant this way (RN 55 down to MT 47).
      private def extract_movement_params(definition_data, definition_file_path, modification_key)
        base = definition_data.dig("Vehicle", "MovementParams")

        return base if modification_key.blank?

        modifications = definition_data.dig("Vehicle", "Modifications", "Modification")
        modifications = [modifications] unless modifications.is_a?(Array)

        patch_file = modifications.compact.find { |modification|
          modification.dig("name") == modification_key
        }&.dig("patchFile")

        return base if patch_file.blank?

        patch_path = "#{definition_path}/#{File.dirname(definition_file_path)}/#{patch_file}.xml"

        return base unless File.exist?(patch_path)

        Hash.from_xml(File.read(patch_path)).dig("Modifications", "MovementParams") || base
      end

      # The Lynx carries a second, stray `Handling` block as a sibling of its
      # movement node; the one nested inside the movement node is the schema
      # correct source, and document order puts it first.
      private def extract_handling_power(movement)
        nested = movement.values.filter_map { |node|
          node.dig("Handling", "Power") if node.is_a?(Hash)
        }.first

        nested || movement.dig("Handling", "Power")
      end

      # `wWheelsMax` is the maximum angular velocity of a wheel in rad/s, so the
      # speed it allows depends on the wheels the vehicle drives on.
      private def extract_wheel_speed_limit(movement, definition_data)
        max_angular_velocity = movement.values.filter_map { |node|
          node.dig("PhysicsParams", "wWheelsMax") if node.is_a?(Hash)
        }.first&.to_f

        return if max_angular_velocity.blank?

        radius = extract_driven_wheel_radius(definition_data)

        return if radius.blank?

        (max_angular_velocity * radius).round(2)
      end

      private def extract_driven_wheel_radius(definition_data)
        wheels = collect_nodes(definition_data.dig("Vehicle", "Parts"), "SubPartWheel")
        driven = wheels.select { |wheel| wheel.dig("driving") == "1" }

        (driven.presence || wheels).filter_map { |wheel| wheel.dig("rimRadius")&.to_f }.max
      end

      private def collect_nodes(node, name)
        case node
        when Array
          node.flat_map { |child| collect_nodes(child, name) }
        when Hash
          node.flat_map do |key, value|
            next Array.wrap(value) if key == name

            collect_nodes(value, name)
          end
        else
          []
        end
      end

      # The ship's shared weapon-power pool size (in power segments). Sustained
      # DPS throttles once the mounted weapons' combined power draw exceeds it.
      # Ships without a fixed weapon pool are power-unlimited (nil).
      private def extract_weapon_pool_size(values)
        pools = values.dig(
          "Components",
          "SItemPortContainerComponentParams",
          "resourceNetworkPowerPools",
          "itemPools",
          "FixedPowerPool"
        )
        return if pools.blank?

        pools = [pools] if pools.is_a?(Hash)
        weapon_pool = pools.find { |pool| pool["itemType"] == "WeaponGun" }
        weapon_pool&.dig("poolSize")&.to_i
      end

      # The ship's manual radar cross-section per axis — its passive
      # detectability. erkul lets you pick which axis (x/y/z) to read.
      private def extract_cross_section(values)
        cross_section = values.dig(
          "Components",
          "SSCSignatureSystemParams",
          "radarProperties",
          "SSCRadarContactProperites",
          "crossSectionParams",
          "SSCSignatureSystemManualCrossSectionParams",
          "crossSection"
        )
        return if cross_section.blank?

        {
          x: cross_section["x"].to_f,
          y: cross_section["y"].to_f,
          z: cross_section["z"].to_f
        }
      end

      private def collect_hull_parts(node, parts = [])
        case node
        when Array
          node.each { |value| collect_hull_parts(value, parts) }
        when Hash
          if node["name"].present? && node["class"] != "ItemPort"
            damage_max = node["damageMax"].to_f
            parts << {name: node["name"], health: damage_max, category: part_category(node, damage_max)}
          end
          collect_hull_parts(node.dig("Parts", "Part"), parts)
        end

        parts
      end

      # Mirrors the part grouping erkul.games shows: a part with no health at all
      # (doors, ladders, step plates) is cosmetic, a part that triggers ship
      # destruction is vital, a standalone detachable part is secondary, a
      # structural part with sub-parts is breakable, and a leaf detail is a subpart.
      private def part_category(node, damage_max)
        return "cosmetic" unless damage_max.positive?

        behaviors = Array.wrap(node.dig("DamageBehaviors", "DamageBehavior")).map { |behavior| behavior["class"] }

        return "vital" if behaviors.include?("Group")
        return "secondary" if behaviors.include?("DetachPart")

        node["Parts"].present? ? "breakable" : "subpart"
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
