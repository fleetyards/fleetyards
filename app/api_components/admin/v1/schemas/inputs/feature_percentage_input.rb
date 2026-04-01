# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FeaturePercentageInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              percentage: {type: :integer, minimum: 0, maximum: 100}
            },
            additionalProperties: false,
            required: %w[percentage]
          })
        end
      end
    end
  end
end
