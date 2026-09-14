# frozen_string_literal: true

module V1
  module Schemas
    class SupporterClaimKey
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          # Never null: reading generates one, so there is no state in which an
          # authenticated caller gets a response without a key.
          key: {type: :string}
        },
        required: %w[key],
        additionalProperties: false
      })
    end
  end
end
