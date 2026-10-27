# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class RaffleGiftCode
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            code: {type: :string}
          },
          additionalProperties: false,
          required: %w[code]
        })
      end
    end
  end
end
