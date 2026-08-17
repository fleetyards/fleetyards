# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class CommodityInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              description: {type: [:string, :null]},
              commodityType: {type: [:string, :null]},
              uexId: {type: [:integer, :null]},
              uexCode: {type: [:string, :null]},
              storeImage: {type: [:string, :null]},
              scKey: {type: [:string, :null]},
              scRef: {type: [:string, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
