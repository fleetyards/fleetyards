# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanPurchase
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              kind: ::V1::Schemas::Enums::HangarPlanPurchaseKindEnum,
              fromModel: {
                anyOf: [::V1::Schemas::Hangar::Plans::HangarPlanModel, {type: :null}],
                description: "For an upgrade: the ship it leads from"
              },
              model: {
                anyOf: [::V1::Schemas::Hangar::Plans::HangarPlanModel, {type: :null}],
                description: "The ship bought or upgraded to; null for a paint, module or upgrade fitted to one"
              },
              name: {type: :string},
              price: {type: [:number, :null], description: "What every unit costs together in USD; null when any price is unknown"},
              quantity: {type: :integer, minimum: 1},
              tokenCount: {type: :integer, minimum: 0, description: "Units paid for with a buy-back token"},
              slotIds: {type: :array, items: {type: :string, format: :uuid}},
              notOnSale: {type: :boolean},
              cartItems: {
                type: :array,
                items: ::V1::Schemas::Hangar::Plans::HangarPlanCartItem,
                description: "One per unit RSI's cart can take; empty on a shared plan"
              }
            },
            additionalProperties: false,
            required: %w[kind fromModel model name quantity tokenCount slotIds notOnSale cartItems]
          })
        end
      end
    end
  end
end
