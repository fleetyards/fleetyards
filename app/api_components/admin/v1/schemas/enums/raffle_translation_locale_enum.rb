# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class RaffleTranslationLocaleEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Raffle::TRANSLATION_LOCALES,
            "x-enumNames": ::Raffle::TRANSLATION_LOCALES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
