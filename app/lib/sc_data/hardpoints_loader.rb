# frozen_string_literal: true

module ScData
  class HardpointsLoader < ::ScData::BaseLoader
    attr_accessor :components_loader

    def initialize(components_loader:)
      super()

      self.components_loader = components_loader || ::ScData::ComponentsLoader.new
    end

    def load(model, components)
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

    private def extract_main_thrusters(hardpoint_type, model_id, components)
      hardpoint_ids = []

      components.select do |component_ref|
        component_ref['itemPortName'].downcase =~ /^hardpoint_(thruster_vtol|vtol|thruster_retro|retro|thruster_main|engine).*/
      end.map do |component_ref|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, component_ref)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_maneuvering_thrusters(hardpoint_type, model_id, components)
      hardpoint_ids = []

      components.select do |component_ref|
        component_ref['itemPortName'].downcase =~ /^hardpoint_thruster_(bottom|top|side|center|mav).*/
      end.map do |component_ref|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, component_ref)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_quantum_drives(hardpoint_type, model_id, components)
      hardpoint_ids = []

      components.select do |component_ref|
        component_ref['itemPortName'].downcase =~ /^hardpoint_quantum_drive.*/
      end.map do |component_ref|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, component_ref)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_power_plants(hardpoint_type, model_id, components)
      hardpoint_ids = []

      components.select do |component_ref|
        component_ref['itemPortName'].downcase =~ /^hardpoint_(powerplant|power_plant).*/
      end.map do |component_ref|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, component_ref)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_coolers(hardpoint_type, model_id, components)
      hardpoint_ids = []

      components.select do |component_ref|
        component_ref['itemPortName'].downcase =~ /^hardpoint_cooler.*/
      end.map do |component_ref|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, component_ref)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_shield_generators(hardpoint_type, model_id, components)
      hardpoint_ids = []

      components.select do |component_ref|
        component_ref['itemPortName'].downcase =~ /^hardpoint_shield_generator.*/
      end.map do |component_ref|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, component_ref)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_missiles(hardpoint_type, model_id, components)
      hardpoint_ids = []

      components.select do |component_ref|
        component_ref['itemPortName'].downcase =~ /.*missile.*/
      end.map do |component_ref|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, component_ref)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_turrets(hardpoint_type, model_id, components)
      hardpoint_ids = []

      components.select do |component_ref|
        loadouts = component_ref.dig('loadout', 'SItemPortLoadoutManualParams', 'entries')
        component_ref['itemPortName'].downcase =~ /.*turret.*/ && loadouts.present?
      end.map do |component_ref|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, component_ref)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_weapons(hardpoint_type, model_id, components)
      hardpoint_ids = []

      components.select do |component_ref|
        loadouts = component_ref.dig('loadout', 'SItemPortLoadoutManualParams', 'entries')
        component_ref['itemPortName'].downcase =~ /^hardpoint_(weapon|gun).*/ && loadouts.present?
      end.map do |component_ref|
        hardpoint_ids << extract_hardpoint(hardpoint_type, model_id, component_ref)&.id
      end

      hardpoint_ids.compact
    end

    private def extract_hardpoint(hardpoint_type, model_id, component_ref)
      sleep 2

      component_data = components_loader.extract_from_ref(component_ref)

      return if component_data.blank?

      hardpoint = ModelHardpoint.find_or_create_by!(
        source: :game_files,
        model_id: model_id,
        hardpoint_type: hardpoint_type,
        group: group_for_hardpoint_type(hardpoint_type),
        key: key_for_hardpoint_type(hardpoint_type, component_ref, component_data),
        mount: component_data[:mount],
        size: size_for_type(hardpoint_type, component_data)
      )

      hardpoint.update!(
        details: details_mapping(component_data.dig(:base, :sub_type)),
        category: category(component_ref, component_data),
        item_slots: item_slots(component_data),
        deleted_at: nil
      )

      component = if %i[turrets weapons missiles].include?(hardpoint_type) && component_data[:loadout_identifier].present?
                    components_loader.create_or_update(component_data[:loadout_identifier])
                  else
                    components_loader.create_or_update(component_data[:identifier])
                  end

      hardpoint.update(component_id: component.id) if component.present?

      hardpoint
    end

    private def group_for_hardpoint_type(hardpoint_type)
      ModelHardpoint.types_by_group.find do |_group, items|
        items.key?(hardpoint_type.to_s)
      end.first
    end

    private def item_slots(component_data)
      component_data[:ports].present? ? component_data[:ports].size : 0
    end

    private def extract_category_from_name(component_name)
      return :vtol if component_name.downcase.include?('vtol')
      return :retro if component_name.downcase.include?('retro')
      return :main if component_name.downcase.match?(/(main|engine)/)

      nil
    end

    private def category(component_ref, component_data)
      extract_category_from_name(component_ref['itemPortName']) || component_data.dig(:base, :category)
    end

    private def key_for_hardpoint_type(hardpoint_type, component_ref, component_data)
      [
        hardpoint_type,
        size_for_type(hardpoint_type, component_data),
        item_slots(component_data),
        category(component_ref, component_data),
        (component_data[:identifier] unless %i[turrets main_thrusters].include?(hardpoint_type)),
        (component_data[:loadout_identifier] if %i[missiles turrets].include?(hardpoint_type))
      ].compact.join('-')
    end

    private def size_for_type(hardpoint_type, component_data)
      component_size = component_data.dig(:base, :size).to_i
      loadout_size = component_data.dig(:ports, 0, 'MaxSize').to_i

      return loadout_size if [:turrets].include?(hardpoint_type) && loadout_size.present?

      size_mapping([component_size, loadout_size].max, hardpoint_type)
    end

    private def size_mapping(size, hardpoint_type)
      mapping = {
        '1' => :small,
        '2' => :medium,
        '3' => :large,
        '4' => :capital
      }

      return mapping[size.to_s] if %i[power_plants coolers shield_generators quantum_drives].include?(hardpoint_type) && mapping[size.to_s].present?

      size
    end

    private def details_mapping(details)
      mapping = {

      }

      return if mapping[details].blank?

      mapping[details]
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

# scunpacked

# countermeasures hardpoint_countermeasures

# armor hardpoint_armor
