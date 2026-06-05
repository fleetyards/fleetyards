# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelHardpointLoadoutInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: [:string, :null]},
              componentId: {type: [:string, :null], format: :uuid},
              modelHardpointId: {type: [:string, :null], format: :uuid}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
