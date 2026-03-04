# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelPaintInput
          include Rswag::SchemaComponents::Component

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
              storeImage: {type: :string},
              rsiStoreImage: {type: :string},
              fleetchartImage: {type: :string},
              topView: {type: :string},
              sideView: {type: :string},
              angledView: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
