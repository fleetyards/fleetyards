# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BlueprintCostOption
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # "resource" is measured in SCU, "item" in whole pieces.
            type: ::Shared::V1::Schemas::Enums::BlueprintCostTypeEnum,
            quantity: {type: [:number, :null]},
            minQuality: {type: [:integer, :null]},

            # The material as the game names it, which answers even where the
            # commodity catalogue has no row for it.
            commodityKey: {type: [:string, :null]},
            commodity: {
              anyOf: [::Shared::V1::Schemas::BlueprintCostCommodity, {type: :null}]
            }
          },
          additionalProperties: false,
          required: %w[type]
        })
      end
    end
  end
end
