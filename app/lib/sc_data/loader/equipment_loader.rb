module ScData
  module Loader
    class EquipmentLoader < ::ScData::Loader::BaseLoader
      def all
        loaded = load_items("equipment").filter_map { |equipment_data| one(equipment_data)&.id }

        retire(loaded)
      end

      # A record the export dropped keeps its row -- a ledger entry made against
      # it still has to resolve -- but it must stop claiming a build it is no
      # longer part of, or `current_version` would go on offering it.
      #
      # Re-importing the same build is what makes this necessary: a new build
      # leaves the row on its old version, but a reload of the one we are
      # already on leaves it looking current.
      private def retire(loaded)
        # A run that loaded nothing retires nothing. `where.not(id: [])` is
        # `1=1`, so an export that failed to sync -- or an environment whose
        # tree does not carry equipment at all -- would otherwise take the whole
        # catalogue with it.
        return if loaded.blank?

        Equipment.where(version: sc_version).where.not(id: loaded).update_all(version: nil)
      end

      def one(equipment_data)
        return if equipment_data["name"].blank?

        equipment = Equipment.find_by(sc_key: equipment_data["key"])
        equipment ||= Equipment.new(sc_key: equipment_data["key"])

        equipment.update!(update_params(equipment_data))

        equipment
      end

      private def update_params(equipment_data)
        {
          sc_key: equipment_data["key"],
          sc_ref: equipment_data["ref"],
          name: equipment_data["name"],
          description: equipment_data["description"],
          icon: equipment_data["icon"],
          equipment_type: equipment_data["equipment_type"],
          item_type: equipment_data["item_type"],
          sub_type: equipment_data["sub_type"],
          weapon_class: equipment_data["weapon_class"],
          size: equipment_data["size"],
          grade: equipment_data["grade"],
          rate_of_fire: equipment_data["rate_of_fire"],
          range: equipment_data["range"],
          storage: equipment_data["storage"],
          hidden: equipment_data["hidden"],
          manufacturer: lookup_manufacturer(equipment_data["manufacturer_ref"]),
          version: sc_version
        }
      end
    end
  end
end
