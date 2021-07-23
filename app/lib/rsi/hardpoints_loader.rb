# frozen_string_literal: true

require 'rsi/base_loader'

module Rsi
  class HardpointsLoader < ::Rsi::BaseLoader
    attr_accessor :components_loader

    def initialize(options = {})
      super

      self.components_loader = ::Rsi::ComponentsLoader.new
    end

    def hardpoint_types(sc_identifier = nil)
      return ModelHardpoint::SHIP_MATRIX_HARDPOINT_TYPES.keys if sc_identifier.present?

      ModelHardpoint::GAME_FILE_HARDPOINT_TYPES.keys + ModelHardpoint::SHIP_MATRIX_HARDPOINT_TYPES.keys
    end

    def run(data, model)
      hardpoint_ids = []

      cleanup_game_file_hardpoints(model.id, model.sc_identifier)

      hardpoints_data(data, model.sc_identifier).each do |hardpoint_data|
        (1..hardpoint_data[:mounts].to_i).each do |mount|
          hardpoint_ids << create_or_update(hardpoint_data, model.id, mount).id
        end
      end

      cleanup_old_hardpoints(model.id, model.sc_identifier, hardpoint_ids)
    end

    private def cleanup_game_file_hardpoints(model_id, model_sc_identifier)
      ModelHardpoint.where(
        source: :game_files,
        model_id: model_id,
        hardpoint_type: hardpoint_types(model_sc_identifier)
      ).update(deleted_at: Time.zone.now)
    end

    private def cleanup_old_hardpoints(model_id, model_sc_identifier, hardpoint_ids)
      ModelHardpoint.where(
        source: :ship_matrix,
        model_id: model_id,
        hardpoint_type: hardpoint_types(model_sc_identifier)
      ).where.not(id: hardpoint_ids)
        .update(deleted_at: Time.zone.now)
    end

    private def hardpoints_data(data, sc_identifier)
      data.values.map do |types|
        types.values.map do |values|
          values.each_with_index.map do |value, index|
            value.symbolize_keys.merge(index: index)
          end
        end
      end.flatten.select do |hardpoint_data|
        hardpoint_types(sc_identifier).include?(hardpoint_data[:type].to_sym)
      end
    end

    private def create_or_update(hardpoint_data, model_id, mount)
      size = extract_size(hardpoint_data)

      hardpoint = ModelHardpoint.find_or_create_by!(
        source: :ship_matrix,
        model_id: model_id,
        hardpoint_type: hardpoint_data[:type],
        group: component_class_to_group(hardpoint_data[:component_class]),
        key: "#{hardpoint_data[:type]}-#{hardpoint_data[:index]}",
        mount: mount,
        size: size
      )

      hardpoint.update!(
        details: hardpoint_data[:details],
        item_slots: hardpoint_data[:quantity],
        category: category_mapping(hardpoint_data[:category]),
        deleted_at: nil
      )

      components_loader.run(hardpoint_data, hardpoint)

      hardpoint
    end

    private def category_mapping(category)
      return if category.blank?

      mapping = {
        'M' => :main,
        'R' => :retro,
        'V' => :vtol,
        'F' => :fixed,
        'G' => :gimbal
      }

      raise "Category missing in Mapping \"#{category}\"" if mapping[category].blank?

      mapping[category]
    end

    private def component_class_to_group(component_class)
      mapping = {
        'RSIPropulsion' => :propulsion,
        'RSIAvionic' => :avionic,
        'RSIThruster' => :thruster,
        'RSIModular' => :system,
        'RSIWeapon' => :weapon
      }

      raise "Component Class missing in Group Mapping \"#{component_class}\"" if mapping[component_class].blank?

      mapping[component_class]
    end

    private def extract_size(hardpoint_data)
      if hardpoint_data[:type] == 'missiles'
        size_from_name = hardpoint_data[:name].scan(/MSD-(\d{1})\d{2}/).last&.first

        return size_mapping(size_from_name || hardpoint_data[:size])
      end

      size_mapping(hardpoint_data[:size])
    end

    private def size_mapping(size)
      mapping = {
        'TBD' => :tbd,
        '-' => :tbd,
        'V' => :vehicle,
        'SN' => :snub,
        'S' => :small,
        'M' => :medium,
        'L' => :large,
        'C' => :capital,
        '1' => :one,
        '2' => :two,
        '3' => :three,
        '4' => :four,
        '5' => :five,
        '6' => :six,
        '7' => :seven,
        '8' => :eight,
        '9' => :nine,
        '10' => :ten,
        '11' => :eleven,
        '12' => :twelve,
      }

      raise "Size missing in Mapping \"#{size}\"" if mapping[size.strip].blank?

      mapping[size.strip]
    end
  end
end
