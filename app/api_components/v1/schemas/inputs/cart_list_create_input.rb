# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CartListCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, minLength: 1, maxLength: 64}
          },
          additionalProperties: false,
          required: %w[name]
        })
      end
    end
  end
end
