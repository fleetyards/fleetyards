# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ExternalFuelTank
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            componentName: {type: :string},
            capacity: {type: :number}
          },
          additionalProperties: false,
          required: %w[capacity]
        })
      end
    end
  end
end
