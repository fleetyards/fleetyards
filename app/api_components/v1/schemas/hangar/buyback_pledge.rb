# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class BuybackPledge
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            rsiPledgeId: {type: :string},
            rsiPage: {type: :integer, description: "The page of the RSI buy-back list the pledge was last read from"},
            kind: ::V1::Schemas::Enums::BuybackPledgeKindEnum,
            name: {type: :string},
            upgraded: {type: :boolean},
            available: {type: :boolean},
            reclaimedOn: {type: :string, format: :date},
            contained: {type: :string},
            image: {type: :string, format: :uri},
            upgradeFromShipId: {type: :integer},
            upgradeToShipId: {type: :integer},
            upgradeToSkuId: {type: :integer},
            price: {type: :number, description: "What buying the pledge back costs, in USD before tax"},
            insuranceMonths: {type: :integer},
            lifetimeInsurance: {type: :boolean},
            insuranceKnown: {type: :boolean, description: "False until the pledge's details are synced, so no insurance listed is not yet none"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id rsiPledgeId kind name upgraded available lifetimeInsurance insuranceKnown createdAt updatedAt]
        })
      end
    end
  end
end
