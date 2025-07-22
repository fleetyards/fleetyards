module Rsi
  class ManufacturersLoader < ::Rsi::BaseLoader
    def run(manufacturer_data, model = nil)
      manufacturer = Manufacturer.find_or_create_by!(rsi_id: manufacturer_data["id"])

      manufacturer.update(
        name: manufacturer_data["name"],
        code: manufacturer_data["code"].presence,
        known_for: manufacturer_data["known_for"].presence,
        description: manufacturer_data["description"].presence
      )

      if !Rails.env.test? && manufacturer.logo.blank? && manufacturer_data["media"].present? && manufacturer_data["media"][0]["source_url"].present?
        manufacturer.update(
          remote_logo_url: "#{base_url}#{manufacturer_data["media"][0]["source_url"]}"
        )
      end

      model.update(manufacturer:) if model.present?

      manufacturer
    end
  end
end
