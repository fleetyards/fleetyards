# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanCartItem
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "What RSI's cart takes for one unit of a purchase",
            properties: {
              kind: ::V1::Schemas::Enums::HangarPlanCartItemKindEnum,
              skuId: {type: :integer, description: "For a store SKU: its RSI id"},
              fromShipId: {type: :integer, description: "For an upgrade: the RSI id of the ship it leads from"},
              toShipId: {type: :integer, description: "For an upgrade: the RSI id of the ship it leads to"},
              toSkuId: {type: :integer, description: "For an upgrade: the RSI upgrade SKU of the ship it leads to"},
              pledgeId: {type: :string, description: "For a buy-back, or an upgrade bought back: the RSI pledge"}
            },
            additionalProperties: false,
            required: %w[kind]
          })
        end
      end
    end
  end
end
