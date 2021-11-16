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
      load_from_export('labels.json')
    end
  end
end
