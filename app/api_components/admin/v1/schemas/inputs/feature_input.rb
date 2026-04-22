# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FeatureInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string}
            },
            additionalProperties: false,
            required: %w[name]
          })
        end
      end
    end
  end
end
