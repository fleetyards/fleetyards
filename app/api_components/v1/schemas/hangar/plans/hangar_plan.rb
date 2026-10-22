# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlan
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              description: {type: [:string, :null]},
              basedOnAt: {type: :string, format: "date-time"},
              startingCredit: {type: :number},
              buybackTokens: {type: [:integer, :null], description: "Buy-back tokens the user holds; each lets one buy-back be paid with store credit. Null uses what the last buy-back sync read"},
              vatRate: {type: [:number, :null], description: "VAT in percent that RSI adds to new money; store credit carries none"},
              syncedBuybackTokens: {type: [:integer, :null], description: "The buy-back tokens the user's last buy-back sync read from RSI"},
              shared: {type: :boolean},
              shareToken: {type: [:string, :null]},
              slotsCount: {type: :integer},
              slots: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanSlot},
              melts: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanMelt},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name basedOnAt startingCredit buybackTokens vatRate syncedBuybackTokens shared slotsCount slots melts createdAt updatedAt]
          })
        end
      end
    end
  end
end
