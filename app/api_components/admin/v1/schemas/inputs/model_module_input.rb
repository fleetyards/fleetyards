# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelModuleInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              description: {type: [:string, :null]},
              modelId: {type: [:string, :null], format: :uuid},
              manufacturerId: {type: :string, format: :uuid},
              price: {type: [:number, :null]},
              pledgePrice: {type: [:number, :null]},
              productionStatus: {type: :string},
              active: {type: :boolean},
              hidden: {type: :boolean},
              storeImage: {type: :string},
              scKey: {type: [:string, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
