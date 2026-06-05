# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelHardpointInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: [:string, :null]},
              source: {type: [:string, :null]},
              key: {type: [:string, :null]},
              hardpointType: {type: [:string, :null]},
              group: {type: [:string, :null]},
              category: {type: [:string, :null]},
              subCategory: {type: [:string, :null]},
              size: {type: [:string, :null]},
              details: {type: [:string, :null]},
              mount: {type: [:string, :null]},
              itemSlots: {type: [:integer, :null]},
              loadoutIdentifier: {type: [:string, :null]},
              componentId: {type: [:string, :null], format: :uuid},
              modelId: {type: [:string, :null], format: :uuid}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
