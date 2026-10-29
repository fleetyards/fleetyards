# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # A field left out shows the English text in that language.
      class RaffleTranslation
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            locale: ::Admin::V1::Schemas::Enums::RaffleTranslationLocaleEnum,
            title: {type: :string},
            description: {type: :string},
            prize: {type: :string}
          },
          additionalProperties: false,
          required: %w[locale]
        })
      end
    end
  end
end
