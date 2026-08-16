module ScData
  module Loader
    class EquipmentLoader < ::ScData::Loader::BaseLoader
      def all
        load_items("equipment").each do |equipment_data|
          one(equipment_data)
        end
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
