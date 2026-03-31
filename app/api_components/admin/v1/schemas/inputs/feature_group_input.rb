# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FeatureGroupInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              group: {type: :string}
            },
            additionalProperties: false,
            required: %w[group]
          })
        end
      end
    end
  end
end
