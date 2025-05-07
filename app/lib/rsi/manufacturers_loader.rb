module Rsi
  class ManufacturersLoader < ::Rsi::BaseLoader
    def one(manufacturer_data)
      manufacturer = Manufacturer.find_by(rsi_id: manufacturer_data["id"])
      manufacturer = Manufacturer.find_by(code: manufacturer_data["code"], rsi_id: nil) if manufacturer.blank?
      manufacturer = Manufacturer.find_by(name: manufacturer_data["name"], rsi_id: nil) if manufacturer.blank?
      if manufacturer.blank?
        manufacturer = Manufacturer.create!(
          name: manufacturer_data["name"],
          rsi_id: manufacturer_data["id"],
          code: manufacturer_data["code"]
        )
      end

      manufacturer.update!(
        rsi_id: manufacturer_data["id"],
        name: manufacturer_data["name"],
        code: manufacturer_data["code"].presence,
        known_for: manufacturer_data["known_for"].presence,
        description: manufacturer_data["description"].presence
      )

      if !Rails.env.test? && (manufacturer.logo.blank? && manufacturer_data["media"].present? && manufacturer_data["media"][0]["source_url"].present?)
        manufacturer.update(
          remote_logo_url: "#{base_url}#{manufacturer_data["media"][0]["source_url"]}"
        )
      end

      manufacturer
    end
  end
end
