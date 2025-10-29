module ScData
  module Loader
    class ItemsLoader < ::ScData::Loader::BaseLoader
      def all
        load_items("items").each do |item|
          next if item["category"] == "inventory"

          normalized_key = item["key"].downcase
          name = item["name"]
          component = find_or_create_component(normalized_key, item["key"], item["ref"], name)

          update_params = {
            sc_key: normalized_key,
            sc_ref: item["ref"],
            hidden: true,
            category: item["category"],
            component_type: item["type"],
            component_sub_type: item["sub_type"],
            size: item["size"],
            grade: item["grade"],
            description: item["description"]
          }

          if name.present?
            update_params[:name] = name
          end

          if categories.include?(item["category"])
            update_params[:hidden] = false
          end

          if item[:ammunition].present?
            update_params[:ammunition] = item[:ammunition]
          end

          if item[:type_data].present?
            update_params[:type_data] = item[:type_data]
          end

          if item[:inventory_ref].present?
            cargo_grid = find_item_by_ref("items", item[:inventory_ref])&.dig(:type_data)
            update_params[:type_data] = cargo_grid if cargo_grid.present?
          end

          if item[:power_connection].present?
            update_params[:power_connection] = item[:power_connection]
          end

          if item[:heat_connection].present?
            update_params[:heat_connection] = item[:heat_connection]
          end

          if item[:inventory_consumption].present?
            update_params[:inventory_consumption] = item[:inventory_consumption]
          end

          if item["manufacturer_ref"].present?
            manufacturer = lookup_manufacturer(item["manufacturer_ref"])
            if manufacturer.present?
              update_params[:manufacturer_id] = manufacturer.id
            end
          end

          if item["loadout"].present?
            add_loadout(item, component)
          end

          component.update!(update_params)
        end
      end

      private def add_loadout(item, component)
        hardpoint_ids = []

        item["loadout"].each do |loadout|
          default_loadout = item["default_loadout"]&.find { |dl| dl["name"] == loadout["name"] }

          next if loadout_name_blacklisted?(loadout["name"], default_loadout)

          hardpoint = component.hardpoints.find_or_create_by!(sc_name: loadout["name"].downcase)
          hardpoint_ids << hardpoint.id

          update_params = {
            source: :game_files,
            min_size: loadout["min_size"],
            max_size: loadout["max_size"],
            types: loadout["types"]
          }

          if default_loadout.present?
            update_params = add_default_loadout(
              default_loadout,
              loadout["name"],
              update_params
            )
          end

          hardpoint.update!(update_params)
        end

        component.hardpoints.where.not(id: hardpoint_ids).destroy_all
      end

      private def add_default_loadout(default_loadout, name, update_params)
        return update_params if default_loadout.blank?

        loadout_component = find_component(default_loadout["key"]&.downcase, default_loadout["key"], default_loadout["ref"])

        update_params[:component_id] = loadout_component&.id

        update_params
      end

      private def find_component(normalized_key, key, ref = nil, name = nil)
        return if normalized_key.blank? && ref.blank?

        component = Component.find_by(sc_key: normalized_key, version: sc_version) if normalized_key.present?
        component = Component.find_by(sc_ref: ref, version: sc_version) if component.blank? && ref.present?
        component = Component.find_by(sc_identifier: key, version: sc_version) if component.blank? && key.present?
        component = Component.where(name: name, sc_key: nil, sc_ref: nil, version: sc_version).first if component.blank? && name.present?

        component
      end

      private def find_or_create_component(normalized_key, key, ref, name)
        return if normalized_key.blank? && ref.blank?

        component = find_component(normalized_key, key, ref, name)

        component = Component.create!(sc_key: normalized_key, sc_ref: ref, version: sc_version) if component.blank?

        component
      end

      private def categories
        %w[
          armor batteries computers missile_racks bombcompartments cooler module powerplant
          quantumdrive quantumenforcementdevice shieldgenerator turret utility weapon_mounts weapons
          lifesupport thrusters radar scanners fueltanks fuel_intakes countermeasures seat relay
          salvagemunching salvagefillerstation selfdestruct paints controller cargogrid jumpdrive
        ]
      end
    end
  end
end
