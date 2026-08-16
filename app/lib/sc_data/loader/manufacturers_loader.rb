module ScData
  module Loader
    class ManufacturersLoader < ::ScData::Loader::BaseLoader
      def all
        load_items("manufacturers").each do |manufacturer_data|
          manufacturer = Manufacturer.find_by(sc_ref: manufacturer_data["ref"])
          manufacturer = Manufacturer.find_by(code: manufacturer_data["code"], sc_ref: nil) if manufacturer.blank?
          manufacturer = Manufacturer.find_by(name: manufacturer_data["name"], sc_ref: nil) if manufacturer.blank? && manufacturer_data["name"].present?

          if manufacturer.present?
            # The description and the code are left alone once set, because a
            # curated one is better than the game's. The icon has no curated
            # counterpart -- it is a path into the export -- so it follows it.
            update_params = {
              sc_ref: manufacturer_data["ref"],
              icon: manufacturer_data["icon"]
            }

            if manufacturer.description.blank? && manufacturer_data["description"].present?
              update_params[:description] = manufacturer_data["description"]
            end

            if manufacturer.code.blank? && manufacturer_data["code"].present?
              update_params[:code] = manufacturer_data["code"]
            end

            manufacturer.update!(update_params)

            manufacturer
          elsif manufacturer_data["name"].present?
            Manufacturer.create!(
              sc_ref: manufacturer_data["ref"],
              name: manufacturer_data["name"],
              code: manufacturer_data["code"],
              description: manufacturer_data["description"],
              icon: manufacturer_data["icon"]
            )
          end
        end
      end
    end
  end
end
