# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FeatureSelfServiceScopeInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              scope: {type: :string, enum: FeatureSetting::SELF_SERVICE_SCOPES}
            },
            additionalProperties: false,
            required: %w[scope]
          })
        end
      end
    end
  end
end
