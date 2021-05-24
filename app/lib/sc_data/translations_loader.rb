# frozen_string_literal: true

module ScData
  class TranslationsLoader < BaseLoader
    attr_accessor :translations

    def initialize
      super

      self.translations = load_translations
    end

    def translate(key)
      return if key.blank?

      translations[key.delete('@')] || key
    end

    private def load_translations
      response = fetch_remote('labels.json')

      return {} unless response.success?

      parse_json_response(response)
    end
  end
end
