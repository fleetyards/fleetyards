# frozen_string_literal: true

module V1
  module Schemas
    class SupporterClaimKey
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          # Null until the account asks for one, which is a normal response
          # rather than an error, so the contract has to allow it.
          key: {type: [:string, :null]}
        },
        required: %w[key],
        additionalProperties: false
      })
    end
  end
end
