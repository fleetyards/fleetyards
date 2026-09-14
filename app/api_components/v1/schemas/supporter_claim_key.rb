# frozen_string_literal: true

module V1
  module Schemas
    class SupporterClaimKey
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          # Null until the account asks for one.
          key: {type: :string}
        },
        required: %w[key],
        additionalProperties: false
      })
    end
  end
end
