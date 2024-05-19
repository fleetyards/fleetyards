module ScData
  class HardpointsLoader < ::ScData::BaseLoader
    attr_accessor :components_loader

    A2_MODEL_ID = "d8e30072-ca4f-4e16-a2b2-e97a2053f989"

    def initialize(components_loader:)
      super()

      self.components_loader = components_loader || ::ScData::ComponentsLoader.new
    end

    def extract_from_components(model, components)
      hardpoint_ids = []

      cleanup_ship_matrix_hardpoints(model.id)

      hardpoint_types.each do |hardpoint_type|
        hardpoint_ids << send(:"extract_#{hardpoint_type}", hardpoint_type, model.id, components)
      end

      cleanup_old_hardpoints(model.id, hardpoint_ids)
    end

    private def hardpoint_types
      ModelHardpoint::GAME_FILE_HARDPOINT_TYPES.keys
    end

    private def extract_fuel_tanks(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["HydrogenFuelTanks"].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_main_thrusters(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["MainThrusters"].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, :main)&.id
      end

      ports_data["VtolThrusters"].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, :vtol)&.id
      end

      ports_data["RetroThrusters"].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, :retro)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_maneuvering_thrusters(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["ManeuveringThrusters"].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, category_for_thruster_mapping(port_data))&.id
      end

      hardpoint_ids.compact
    end

    private def extract_quantum_drives(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["QuantumDrives"].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_utility_items(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["UtilityHardpoints"].reject do |port_data|
        port_data["PortName"].include?("controller")
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      ports_data["UtilityTurrets"].reject do |port_data|
        port_data["PortName"].include?("camera")
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, "utility_turret")&.id
      end

      ports_data["MiningHardpoints"].reject do |port_data|
        port_data["PortName"].include?("controller")
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      ports_data["MiningTurrets"].reject do |port_data|
        port_data["PortName"].include?("camera")
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, "mining_turret")&.id
      end

      hardpoint_ids.compact
    end

    private def extract_power_plants(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["PowerPlants"].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_coolers(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["Coolers"].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_shield_generators(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["Shields"].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_missiles(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["PilotHardpoints"].each_with_index.map do |port_data, index|
        next if port_data["Flags"]&.include?("invisible")
        next unless port_data["PortName"].include?("bombrack")

        category = port_data["PortName"].include?("turret") ? "missile_turret" : nil
        key_modifier = port_data.dig("InstalledItem", "Ports", 0, "Loadout")
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, category, key_modifier)&.id
      end

      ports_data["MissileRacks"].each_with_index.map do |port_data, index|
        next if port_data["Flags"]&.include?("invisible")
        # Hack for A2 missile racks on the Starlifter
        next if model_id == A2_MODEL_ID && port_data["InstalledItem"].blank?

        puts port_data["InstalledItem"].inspect

        category = port_data["PortName"].include?("turret") ? "missile_turret" : nil
        key_modifier = port_data.dig("InstalledItem", "Ports", 0, "Loadout")
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, category, key_modifier)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_turrets(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["MannedTurrets"].reject do |port_data|
        missile_turret?(port_data) || port_data["PortName"].include?("camera") || port_data["PortName"].include?("lighting")
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, "manned_turret")&.id
      end

      ports_data["RemoteTurrets"].reject do |port_data|
        missile_turret?(port_data) || port_data["PortName"].include?("camera") || port_data["PortName"].include?("lighting")
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, "remote_turret")&.id
      end

      hardpoint_ids.compact
    end

    private def extract_weapons(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["PilotHardpoints"].each_with_index.map do |port_data, index|
        next if port_data["PortName"].include?("bombrack")
        next if port_data["Loadout"].present? && port_data["Loadout"].include?("CRUS_Starlifter_Bomb_Turret")

        key_modifier = "#{port_data["Loadout"]}_#{port_data.dig("InstalledItem", "Ports", 0, "Loadout")}"
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, nil, key_modifier)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_qed(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      exclude_model_ids = [
        "dc7f4408-c474-4d54-b105-227991ab64b3",
        "b94e105b-8b8c-47f0-975c-5e6a3d1a3134",
        "14b8dbc7-9f4d-42a0-9158-a9ecaa0795d7"
      ]

      ports_data["InterdictionHardpoints"].reject do |port_data|
        (port_data["Flags"] || []).include?("invisible") && exclude_model_ids.include?(model_id)
      end.select do |port_data|
        port_data["Types"].include?("QuantumInterdictionGenerator")
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, "qed")&.id
      end

      hardpoint_ids.compact
    end

    private def extract_emp(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data["InterdictionHardpoints"].select do |port_data|
        port_data["Types"].include?("EMP")
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, "emp")&.id
      end

      hardpoint_ids.compact
    end

    # rubocop:disable Metrics/ParameterLists
    private def extract_hardpoint(hardpoint_type, model_id, port_data, index, category = nil, key_modifier = nil)
      size = size_for_type(hardpoint_type, port_data, category)

      component_data = port_data["InstalledItem"] || {}

      loadout_key = extract_loadout_key(hardpoint_type, port_data)

      key = [key_modifier, hardpoint_type, category, size, loadout_key].compact.join("-")

      hardpoint = ModelHardpoint.find_or_create_by!(
        source: :game_files,
        model_id:,
        key:,
        name: port_data["PortName"],
        item_slot: index,
        loadout_identifier: component_data["Name"],
        group: group_for_hardpoint_type(hardpoint_type)
      ) do |new_hardpoint|
        new_hardpoint.hardpoint_type = hardpoint_type
        new_hardpoint.category = category
        new_hardpoint.size = size
      end

      # Hack for A2 missile racks on the Starlifter
      if model_id == A2_MODEL_ID && component_data["Name"] == "MSD-313 Missile Rack"
        component_data["Name"] = "A2-10210"
        component_data["Description"] = ""
        component_data["Manufacturer"] = {
          "Code" => "CRUS",
          "Name" => "Crusader Industries"
        }
      end

      if component_data["ClassName"] == "ARGO_SRV_MainTractorBeamArm"
        component_data = component_data.dig("Ports", 0, "InstalledItem", "Ports", 0, "InstalledItem")
      end

      component = components_loader.extract_component!(component_data)

      if component_data["Ports"].present? && component_data.dig("Ports", 0, "PortName")&.exclude?("Consumable")
        extract_loadout(hardpoint, component_data["Ports"])
      end

      hardpoint.update!(
        component_id: component&.id,
        deleted_at: nil
      )

      hardpoint
    end
    # rubocop:enable Metrics/ParameterLists

    private def extract_loadout(hardpoint, ports_data)
      loadout_ids = []

      ports_data.reject do |port_data|
        port_data.dig("InstalledItem", "Type")&.include?("WeaponAttachment") ||
          (port_data["Types"] || []).any? { |type| type.include?("WeaponAttachment") } ||
          port_data["PortName"] == "magazine_attach"
      end.each do |port_data|
        loadout = hardpoint.model_hardpoint_loadouts.find_or_create_by!(name: port_data["PortName"])

        installed_item = port_data["InstalledItem"]

        if installed_item.present? && installed_item["ClassName"].include?("Mount_Gimbal")
          installed_item = installed_item.dig("Ports", 0, "InstalledItem")
        end

        component = components_loader.extract_component!(installed_item)

        loadout.update!(component_id: component&.id)

        loadout_ids << loadout.id
      end

      ModelHardpointLoadout.where(
        model_hardpoint_id: hardpoint.id
      ).where.not(id: loadout_ids.flatten)
        .destroy_all
    end

    private def group_for_hardpoint_type(hardpoint_type)
      ModelHardpoint.types_by_group.find do |_group, items|
        items.key?(hardpoint_type.to_s)
      end.first
    end

    private def extract_loadout_key(hardpoint_type, component)
      return if %i[power_plants coolers shield_generators quantum_drives].include?(hardpoint_type)

      [
        component.dig("InstalledItem", "Ports")&.size,
        component.dig("InstalledItem", "Ports", 0, "Loadout") || component.dig("InstalledItem", "Ports", 0, "InstalledItem", "Name")
      ].compact.join("-")
    end

    private def category_for_thruster_mapping(port_data)
      thruster_loadout_type = port_data.dig("InstalledItem", "Type")

      mapping = {
        "ManneuverThruster.JointThruster": :joint,
        "ManneuverThruster.FixedThruster": :fixed,
        "ManneuverThruster.GimbalThruster": :gimbal
      }

      mapping[thruster_loadout_type&.to_sym]
    end

    private def size_for_type(hardpoint_type, component, category = nil)
      component_size = component["Size"].to_i
      component_size = component.dig("InstalledItem", "Size").to_i if component_size.zero?
      component_size = component.dig("InstalledItem", "Ports", 0, "InstalledItem", "Ports", 0, "InstalledItem", "Size").to_i if component.dig("InstalledItem", "ClassName") == "ARGO_SRV_MainTractorBeamArm"
      loadout_size = component.dig("InstalledItem", "Ports", 0, "Size").to_i

      return [component_size, loadout_size].max if [:turrets].include?(hardpoint_type) && loadout_size.present?

      return loadout_size if %w[manned_missile_turrets remote_missile_turrets].include?(category) && loadout_size.present? && category.present?

      return size_mapping[component_size.to_s] if %i[power_plants coolers shield_generators quantum_drives].include?(hardpoint_type) && size_mapping[component_size.to_s].present?

      component_size
    end

    private def size_mapping
      {
        "1" => :small,
        "2" => :medium,
        "3" => :large,
        "4" => :capital
      }
    end

    private def missile_turret?(component)
      component.dig("InstalledItem", "Type") == "Turret.MissileTurret"
    end

    private def cleanup_ship_matrix_hardpoints(model_id)
      ModelHardpoint.where(
        source: :ship_matrix,
        model_id:,
        hardpoint_type: hardpoint_types
      ).update(deleted_at: Time.zone.now)
    end

    private def cleanup_old_hardpoints(model_id, hardpoint_ids)
      ModelHardpoint.where(
        source: :game_files,
        model_id:,
        hardpoint_type: hardpoint_types
      ).where.not(id: hardpoint_ids.flatten)
        .update(deleted_at: Time.zone.now)
    end
  end
end
