# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RsiBuybackItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string},
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
            page: {type: :integer, description: "The page of the RSI buy-back list the pledge was read from"}
          },
          additionalProperties: false,
          required: %w[id kind name]
        })
      end
    end
  end
end
