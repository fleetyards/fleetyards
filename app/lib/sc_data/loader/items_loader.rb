module ScData
  module Loader
    class ItemsLoader < ::ScData::Loader::BaseLoader
      def all
        exported = load_items("items")
        items = exported.reject { |item| item["category"] == "inventory" }
        items_by_ref = index_by_ref(exported)
        loaded = []
        carrying_icon = component_ids_carrying_icon

        # Pass 1: create/update all components so they exist for cross-references
        items.each do |item|
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
            cargo_grid = items_by_ref[item[:inventory_ref]]&.dig(:type_data)
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

          # Stamped on every load, not just on create: the row is reused across
          # builds now, so this is what records the build it was last seen in.
          update_params[:version] = sc_version

          apply(component, update_params)

          if item["icon"].present?
            attach_icon(component, :icon, item["icon"])
          elsif carrying_icon.include?(component.id)
            component.icon.purge
          end

          loaded << component.id
        end

        # Pass 2: link loadouts (all components now exist for cross-references)
        items.each do |item|
          next if item["loadout"].blank?

          normalized_key = item["key"].downcase
          component = find_component(normalized_key, item["key"], item["ref"])
          add_loadout(item, component)
        end

        retire_absent(Component, loaded)
      end

      # A build that stops shipping a paint's swatch has to take the picture
      # with it. The curated attachments are left alone when the export goes
      # quiet -- a load cannot tell an admin's upload from its own -- but
      # nothing except a load ever writes here, so there is no upload to
      # protect and an icon the current build does not carry would otherwise go
      # on being served.
      #
      # Only for a record that names no icon at all. A path that fails to
      # resolve is a broken parse rather than a dropped picture, and throwing
      # the artwork away over one would lose what the export still carries.
      #
      # Read in one go up front rather than asked per item: almost none of the
      # eight thousand components has an icon, so a single query names the
      # handful that per-item checks would spend eight thousand round trips
      # finding. Dropping the picture then happens beside the update that
      # orphaned it, so a pass that dies partway still takes the icons of
      # everything it got through with it.
      private def component_ids_carrying_icon
        ActiveStorage::Attachment
          .where(record_type: "Component", name: "icon")
          .pluck(:record_id)
          .to_set
      end

      # Same reason, for the export side: `find_item_by_ref` reaches for the
      # tree again on every call and `load_items` globs and parses every one of
      # the eight thousand item files, so resolving the hundred-odd
      # inventory_refs one at a time parsed the whole tree a hundred times over.
      #
      # Indexed off the unfiltered export: an inventory_ref points at exactly
      # the inventory items `all` rejects, so an index over the kept ones would
      # resolve none of them. First match wins, as the scan did.
      private def index_by_ref(items)
        items.each_with_object({}) do |item, index|
          index[item[:ref]] ||= item
        end
      end

      private def add_loadout(item, component)
        hardpoint_ids = []

        item["loadout"].each do |loadout|
          default_loadout = item["default_loadout"]&.find { |dl| dl["name"] == loadout["name"] }

          next if loadout_name_blacklisted?(loadout["name"], default_loadout)

          # Initialized rather than created, so a new hardpoint is one insert
          # with its attributes rather than an insert followed by an update. The
          # id is collected after the save for that reason.
          hardpoint = component.hardpoints.find_or_initialize_by(sc_name: loadout["name"].downcase)

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

          apply(hardpoint, update_params)

          hardpoint_ids << hardpoint.id
        end

        component.hardpoints.where.not(id: hardpoint_ids).destroy_all
      end

      private def add_default_loadout(default_loadout, name, update_params)
        return update_params if default_loadout.blank?

        loadout_component = find_component(default_loadout["key"]&.downcase, default_loadout["key"], default_loadout["ref"])

        update_params[:component_id] = loadout_component&.id

        update_params
      end

      # A component is the same component across builds, so the version is no
      # longer part of its identity -- a row is updated in place and `version`
      # records the build it was last seen in. Commodity and Equipment are keyed
      # the same way; only this loader used to add a row per build, which is why
      # the table kept every patch it had ever imported.
      private def find_component(normalized_key, key, ref = nil, name = nil)
        return if normalized_key.blank? && ref.blank?

        component = Component.find_by(sc_key: normalized_key) if normalized_key.present?
        component = Component.find_by(sc_ref: ref) if component.blank? && ref.present?
        component = Component.where(name: name, sc_key: nil, sc_ref: nil).first if component.blank? && name.present?

        component
      end

      private def find_or_create_component(normalized_key, key, ref, name)
        return if normalized_key.blank? && ref.blank?

        component = find_component(normalized_key, key, ref, name)

        component = apply(Component.new, {sc_key: normalized_key, sc_ref: ref, version: sc_version}) if component.blank?

        component
      end

      private def categories
        %w[
          armor batteries computers missile_racks bombcompartments cooler module powerplant
          quantumdrive quantumenforcementdevice shieldgenerator turret utility weapon_mounts weapons
          lifesupport thrusters radar scanners fueltanks fuel_intakes countermeasures seat relay
          salvagemunching salvagefillerstation selfdestruct paints controller cargogrid jumpdrive
          refuel_boom
        ]
      end
    end
  end
end
