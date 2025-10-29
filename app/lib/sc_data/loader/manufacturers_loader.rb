module ScData
  module Loader
    class ManufacturersLoader < ::ScData::Loader::BaseLoader
      def all
        load_items("manufacturers").each do |manufacturer_data|
          manufacturer = Manufacturer.find_by(sc_ref: manufacturer_data["ref"])
          manufacturer = Manufacturer.find_by(code: manufacturer_data["code"], sc_ref: nil) if manufacturer.blank?
          manufacturer = Manufacturer.find_by(name: manufacturer_data["name"], sc_ref: nil) if manufacturer.blank? && manufacturer_data["name"].present?

          if manufacturer.present?
            update_params = {
              sc_ref: manufacturer_data["ref"]
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
              description: manufacturer_data["description"]
            )
          end
        end
      end
    end
  end
end
