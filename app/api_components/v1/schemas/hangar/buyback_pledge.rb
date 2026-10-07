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
            price: {type: :number},
            priceCurrency: {type: :string},
            insuranceMonths: {type: :integer},
            lifetimeInsurance: {type: :boolean},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id rsiPledgeId kind name upgraded available lifetimeInsurance createdAt updatedAt]
        })
      end
    end
  end
end
