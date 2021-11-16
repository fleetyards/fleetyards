# frozen_string_literal: true

module ScData
  class HardpointsLoader < ::ScData::BaseLoader
    attr_accessor :components_loader

    def initialize(components_loader:)
      super()

      self.components_loader = components_loader || ::ScData::ComponentsLoader.new
    end

    def extract_from_components(model, components)
      hardpoint_ids = []

      cleanup_ship_matrix_hardpoints(model.id)

      hardpoint_types.each do |hardpoint_type|
        hardpoint_ids << send("extract_#{hardpoint_type}", hardpoint_type, model.id, components)
      end

      cleanup_old_hardpoints(model.id, hardpoint_ids)
    end

    private def hardpoint_types
      ModelHardpoint::GAME_FILE_HARDPOINT_TYPES.keys
    end

    private def extract_fuel_tanks(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['HydrogenFuelTanks'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_main_thrusters(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['MainThrusters'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, :main)&.id
      end

      ports_data['VtolThrusters'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, :vtol)&.id
      end

      ports_data['RetroThrusters'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, :retro)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_maneuvering_thrusters(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['ManeuveringThrusters'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, category_for_thruster_mapping(port_data))&.id
      end

      hardpoint_ids.compact
    end

    private def extract_quantum_drives(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['QuantumDrives'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_power_plants(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['PowerPlants'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_coolers(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['Coolers'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_shield_generators(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['Shields'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_missiles(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['MissileRacks'].each_with_index.map do |port_data, index|
        category = port_data['PortName'].include?('turret') ? 'missile_turret' : nil
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, category)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_turrets(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['MannedTurrets'].reject do |port_data|
        missile_turret?(port_data)
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, 'manned_turret')&.id
      end

      ports_data['RemoteTurrets'].reject do |port_data|
        missile_turret?(port_data)
      end.each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index, 'remote_turret')&.id
      end

      hardpoint_ids.compact
    end

    private def extract_weapons(hardpoint_type, model_id, ports_data)
      hardpoint_ids = []

      ports_data['PilotHardpoints'].each_with_index.map do |port_data, index|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, port_data, index)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_hardpoint(hardpoint_type, model_id, port_data, index, category = nil)
      size = size_for_type(hardpoint_type, port_data, category)

      component_data = port_data['InstalledItem'] || {}

      hardpoint = ModelHardpoint.find_or_create_by!(
        source: :game_files,
        model_id: model_id,
        hardpoint_type: hardpoint_type,
        group: group_for_hardpoint_type(hardpoint_type),
        key: [
          hardpoint_type,
          category,
          size
        ].compact.join('-'),
        loadout_identifier: component_data['Name'],
        category: category,
        name: port_data['PortName'],
        item_slot: index,
        size: size
      )

      component = components_loader.extract_component!(component_data)

      extract_loadout(hardpoint, component_data['Ports']) if component_data['Ports'].present?

      hardpoint.update!(
        component_id: component&.id,
        deleted_at: nil
      )

      hardpoint
    end

    private def extract_loadout(hardpoint, ports_data)
      loadout_ids = []

      ports_data.reject do |port_data|
        port_data.dig('InstalledItem', 'Type')&.include?('WeaponAttachment') ||
          (port_data['Types'] || []).any? { |type| type.include?('WeaponAttachment') }
      end.each do |port_data|
        loadout = hardpoint.model_hardpoint_loadouts.find_or_create_by!(name: port_data['PortName'])

        component = components_loader.extract_component!(port_data['InstalledItem'])

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

    private def category_for_thruster_mapping(port_data)
      thruster_loadout_type = port_data.dig('InstalledItem', 'Type')

      mapping = {
        'ManneuverThruster.JointThruster': :joint,
        'ManneuverThruster.FixedThruster': :fixed,
        'ManneuverThruster.GimbalThruster': :gimbal,
      }

      mapping[thruster_loadout_type&.to_sym]
    end

    private def size_for_type(hardpoint_type, component, category = nil)
      component_size = component['Size'].to_i
      loadout_size = component.dig('InstalledItem', 'Ports', 0, 'Size').to_i

      return loadout_size if [:turrets].include?(hardpoint_type) && loadout_size.present?

      return loadout_size if %w[manned_missile_turrets remote_missile_turrets].include?(category) && loadout_size.present? && category.present?

      return size_mapping[component_size] if %i[power_plants coolers shield_generators quantum_drives].include?(hardpoint_type) && size_mapping[component_size].present?

      component_size
    end

    private def size_mapping
      {
        '1' => :small,
        '2' => :medium,
        '3' => :large,
        '4' => :capital
      }
    end

    private def missile_turret?(component)
      component.dig('InstalledItem', 'Type') == 'Turret.MissileTurret'
    end

    private def cleanup_ship_matrix_hardpoints(model_id)
      ModelHardpoint.where(
        source: :ship_matrix,
        model_id: model_id,
        hardpoint_type: hardpoint_types
      ).update(deleted_at: Time.zone.now)
    end

    private def cleanup_old_hardpoints(model_id, hardpoint_ids)
      ModelHardpoint.where(
        source: :game_files,
        model_id: model_id,
        hardpoint_type: hardpoint_types
      ).where.not(id: hardpoint_ids.flatten)
        .update(deleted_at: Time.zone.now)
    end
  end
end
