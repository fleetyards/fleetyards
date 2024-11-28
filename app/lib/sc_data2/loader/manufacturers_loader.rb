module ScData2
  module Loader
    class ManufacturersLoader < ::ScData2::Loader::BaseLoader
      def run
        load_items("manufacturers").each do |manufacturer_data|
          manufacturer = Manufacturer.find_by(sc_ref: manufacturer_data["ref"])
          manufacturer = Manufacturer.find_by(code: manufacturer_data["code"]) if manufacturer.blank?

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
          else
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
