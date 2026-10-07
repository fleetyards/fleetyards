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
            price: {type: :number, minimum: 0, description: "In USD before tax"},
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
