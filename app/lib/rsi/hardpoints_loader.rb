module Rsi
  class HardpointsLoader < ::Rsi::BaseLoader
    def all(model, data = nil)
      hardpoint_ids = []

      if data.blank?
        data = load_data.find do |entry|
          entry["id"].to_s == model.rsi_id.to_s
        end.dig("compiled")
      end

      return if data.blank?

      hardpoints_data(data).each do |hardpoint_data|
        (1..hardpoint_data[:mounts].to_i).each do |mount|
          hardpoint_ids << create_or_update(hardpoint_data, model, mount).id
        end
      end

      cleanup_old_hardpoints(model, hardpoint_ids)
    end

    private def cleanup_old_hardpoints(model, hardpoint_ids)
      Hardpoint.where(
        source: :ship_matrix,
        parent: model
      ).where.not(id: hardpoint_ids)
        .destroy_all
    end

    private def hardpoints_data(data)
      data.values.map do |types|
        types.values.map do |values|
          values.each_with_index.map do |value, index|
            value.symbolize_keys.merge(index:)
          end
        end
      end.flatten
    end

    private def create_or_update(hardpoint_data, model, mount)
      size = size_mapping(hardpoint_data[:size])

      key = [
        hardpoint_data[:name]&.strip&.tr(" ", "-"),
        size,
        hardpoint_data[:component_size],
        hardpoint_data[:index],
        mount
      ].compact.join("_")

      hardpoint = Hardpoint.find_or_create_by!(
        matrix_key: key,
        source: :ship_matrix,
        parent: model
      )

      group_key = [
        hardpoint_data[:type],
        hardpoint_data[:name]&.strip&.tr(" ", "-"),
        size,
        hardpoint_data[:component_size]
      ].compact.join("-")

      hardpoint.update!(
        sc_name: hardpoint_data[:name],
        details: hardpoint_data[:details],
        category: hardpoint_type_to_category(hardpoint_data[:type]),
        group: component_class_to_group(hardpoint_data[:component_class], hardpoint_data[:type]),
        group_key: group_key,
        min_size: size,
        max_size: size
      )

      if hardpoint_data[:quantity].to_i > 1
        hardpoint.hardpoints << (1..hardpoint_data[:quantity].to_i).map do |index|
          sub_hardpoint = Hardpoint.find_or_create_by!(
            matrix_key: "#{hardpoint_data[:name].strip}_#{size}_#{hardpoint_data[:index]}_#{mount}_#{index}",
            source: :ship_matrix,
            parent: hardpoint
          )

          sub_hardpoint.update!(
            sc_name: hardpoint_data[:name],
            group: component_class_to_group(hardpoint_data[:component_class], hardpoint_data[:type]),
            category: hardpoint_type_to_category(hardpoint_data[:type]),
            group_key: "#{hardpoint_data[:type]}-#{size}",
            min_size: size,
            max_size: size
          )

          sub_hardpoint
        end
      end

      hardpoint
    end

    private def component_class_to_group(component_class, hardpoint_type)
      if hardpoint_type == "utility_items"
        return :auxiliary
      end

      mapping = {
        "RSIPropulsion" => :propulsion,
        "RSIAvionic" => :avionic,
        "RSIThruster" => :thruster,
        "RSIModular" => :system,
        "RSIWeapon" => :weapon
      }

      raise "Component Class missing in Group Mapping \"#{component_class}\"" if mapping[component_class].blank?

      mapping[component_class]
    end

    private def hardpoint_type_to_category(hardpoint_type)
      mapping = {
        "fuel_tanks" => :fueltanks,
        "quantum_drives" => :quantumdrive,
        "jump_modules" => :jumpdrive,
        "quantum_fuel_tanks" => :fueltanks,
        "power_plants" => :powerplant,
        "coolers" => :cooler,
        "shield_generators" => :shieldgenerator,
        "turrets" => :turret,
        "missiles" => :missile_racks,
        "utility_items" => :utility
      }

      return hardpoint_type if mapping[hardpoint_type].blank?

      mapping[hardpoint_type]
    end

    private def extract_size(hardpoint_data)
      size_mapping(hardpoint_data[:size])
    end

    private def size_mapping(size)
      mapping = {
        "TBD" => nil,
        "-" => nil,
        "V" => 0,
        "SN" => 0,
        "S" => 1,
        "M" => 2,
        "L" => 3,
        "C" => 4,
        "1" => 1,
        "2" => 2,
        "3" => 3,
        "4" => 4,
        "5" => 5,
        "6" => 6,
        "7" => 7,
        "8" => 8,
        "9" => 9,
        "10" => 10,
        "11" => 11,
        "12" => 12
      }

      raise "Size missing in Mapping \"#{size}\"" if mapping.keys.exclude?(size.strip)

      mapping[size.strip]
    end
  end
end
