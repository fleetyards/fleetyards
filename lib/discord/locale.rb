# frozen_string_literal: true

module Discord
  # Maps the locale Discord sends on an interaction onto one the app has.
  #
  # Discord sends IETF-ish tags ("en-US", "es-ES", "zh-CN"); the app has
  # "en", "de", "es", "fr", "it", "zh-CN", "zh-TW". An exact match wins so the
  # two Chinese locales stay distinct -- collapsing them to "zh" would pick
  # neither.
  module Locale
    def self.resolve(tag)
      return I18n.default_locale if tag.blank?

      available = I18n.available_locales.map(&:to_s)

      exact = available.find { |locale| locale.casecmp?(tag.to_s) }
      return exact.to_sym if exact

      language = tag.to_s.split("-").first
      language_match = available.find { |locale| locale.casecmp?(language) }
      return language_match.to_sym if language_match

      I18n.default_locale
    end
  end
end
