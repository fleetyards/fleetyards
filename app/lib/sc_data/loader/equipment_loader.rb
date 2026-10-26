module ScData
  module Loader
    class EquipmentLoader < ::ScData::Loader::BaseLoader
      def all
        items = load_items("equipment")
        loaded = items.filter_map { |equipment_data| one(equipment_data)&.id }

        link_attachments(items)

        retire_absent_builds(EquipmentBuild, :equipment_id, loaded)

        prune_builds(EquipmentBuild)
      end

      def one(equipment_data)
        return if equipment_data["name"].blank?

        equipment = Equipment.find_by(sc_key: equipment_data["key"])
        equipment ||= Equipment.new(sc_key: equipment_data["key"])

        update_params = update_params(equipment_data)

        apply(equipment, update_params)

        # `sc_key`, `sc_ref` and `family_key` identify the item rather than
        # describing a build, so they stay on the row and are not repeated here.
        builds[equipment_data["key"]] = apply_build(equipment, update_params.except(:sc_key, :sc_ref, :family_key))

        equipment
      end

      # A second pass, once every attachment has a row to point at. Rewritten
      # wholesale for the builds this load wrote rather than reconciled row by
      # row, the way a blueprint's recipe is: nothing points at a fit, and a
      # port CIG narrows has to lose the attachments it no longer takes.
      private def link_attachments(items)
        candidates = items.select { |item| item["equipment_type"] == "weapon_attachment" }.group_by { |item| item["sub_type"] }
        ids = Equipment.where(sc_key: candidates.values.flatten.pluck("key")).pluck(:sc_key, :id).to_h

        rows = items.flat_map do |item|
          build = builds[item["key"]]

          next [] if build.nil?

          Array.wrap(item["ports"]).flat_map { |port| attachment_rows(build, port, candidates, ids) }
        end

        EquipmentAttachment.transaction do
          EquipmentAttachment.where(equipment_build_id: builds.values.map(&:id)).delete_all

          rows.each_slice(5_000) { |slice| EquipmentAttachment.insert_all!(slice) }
        end

        stats[EquipmentAttachment.name][:created] += rows.size
      end

      # The game's rule: one of the port's subtypes, a size in its range, every
      # tag the port requires on the attachment and every tag the attachment
      # requires on the port. What the weapon ships with is taken as fitting
      # whether or not the tags say so.
      private def attachment_rows(build, port, candidates, ids)
        now = Time.zone.now

        fitting = port["sub_types"].flat_map { |sub_type| candidates.fetch(sub_type, []) }.select do |attachment|
          attachment["key"] == port["default"] || fits?(port, attachment)
        end

        fitting.uniq { |attachment| attachment["key"] }.filter_map do |attachment|
          attachment_id = ids[attachment["key"]]

          next if attachment_id.nil?

          {
            id: SecureRandom.uuid,
            equipment_build_id: build.id,
            attachment_id:,
            port_name: port["name"],
            port_type: port["sub_types"].first,
            default: attachment["key"] == port["default"],
            created_at: now,
            updated_at: now
          }
        end
      end

      private def fits?(port, attachment)
        size = Integer(attachment["size"], exception: false)

        return false if size.nil? || !size.between?(port["min_size"], port["max_size"])
        return false if (Array(port["required_tags"]) - Array(attachment["tags"])).any?

        (Array(attachment["required_tags"]) - Array(port["port_tags"])).empty?
      end

      private def builds
        @builds ||= {}
      end

      private def update_params(equipment_data)
        {
          sc_key: equipment_data["key"],
          sc_ref: equipment_data["ref"],
          name: equipment_data["name"],
          description: equipment_data["description"],
          equipment_type: equipment_data["equipment_type"],
          item_type: equipment_data["item_type"],
          sub_type: equipment_data["sub_type"],
          weapon_class: equipment_data["weapon_class"],
          size: equipment_data["size"],
          grade: equipment_data["grade"],
          slot: equipment_data["slot"],
          rate_of_fire: equipment_data["rate_of_fire"],
          range: equipment_data["range"],
          storage: equipment_data["storage"],
          damage_reduction: equipment_data["damage_reduction"],
          temperature_rating: equipment_data["temperature_rating"],
          radiation_protection: equipment_data["radiation_protection"],
          radiation_scrub_rate: equipment_data["radiation_scrub_rate"],
          g_force_tolerance: equipment_data["g_force_tolerance"],
          core_compatibility: equipment_data["core_compatibility"],
          backpack_compatibility: equipment_data["backpack_compatibility"],
          volume: equipment_data["volume"],
          volume_dimensions: equipment_data["volume_dimensions"],
          hidden: equipment_data["hidden"],
          family_key: equipment_data["family_key"],
          manufacturer: lookup_manufacturer(equipment_data["manufacturer_ref"])
        }
      end
    end
  end
end
