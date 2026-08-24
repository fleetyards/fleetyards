# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelPaintInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              description: {type: :string},
              modelId: {type: :string, format: :uuid},
              active: {type: :boolean},
              hidden: {type: :boolean},
              onSale: {type: :boolean},
              pledgePrice: {type: :number},
              productionStatus: {type: :string},
              productionNote: {type: :string},
              storeUrl: {type: :string},
              storeImage: {type: [:string, :null]},
              rsiStoreImage: {type: [:string, :null]},
              fleetchartImage: {type: [:string, :null]},
              topView: {type: [:string, :null]},
              sideView: {type: [:string, :null]},
              angledView: {type: [:string, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
