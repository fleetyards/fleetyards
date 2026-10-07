# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RsiBuybackDetailInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string},
            price: {type: :number, minimum: 0},
            currency: {type: :string, pattern: "^[A-Z]{3}$"},
            insuranceMonths: {type: :integer, minimum: 0},
            lifetimeInsurance: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[id]
        })
      end
    end
  end
end
