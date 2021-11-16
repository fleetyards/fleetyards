# frozen_string_literal: true

module ScData
  class BaseLoader
    private def load_from_export(path)
      full_path = Rails.root.join("public/sc_data/#{path}")

      raw_data = File.read(full_path) if File.exist?(full_path)

      parse_json(raw_data) if raw_data.present?
    end

    private def parse_json(raw_data)
      JSON.parse(raw_data)
    rescue JSON::ParserError => e
      Raven.capture_exception(e)
      Rails.logger.error "SC Data could not be parsed: #{raw_data}"
      nil
    end
  end
end
