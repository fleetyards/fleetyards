# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FeatureGroupInput
          include OpenapiRuby::Components::Base

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
