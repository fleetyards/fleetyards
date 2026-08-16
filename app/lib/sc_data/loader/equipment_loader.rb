module ScData
  module Loader
    class EquipmentLoader < ::ScData::Loader::BaseLoader
      def all
        loaded = load_items("equipment").filter_map { |equipment_data| one(equipment_data)&.id }

        retire_absent(Equipment, loaded)
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
          manufacturer: lookup_manufacturer(equipment_data["manufacturer_ref"]),
          version: sc_version
        }
      end
    end
  end
end
