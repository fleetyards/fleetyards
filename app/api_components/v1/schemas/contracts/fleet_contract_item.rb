# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      class FleetContractItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            category: ::V1::Schemas::Enums::InventoryCategoryEnum,
            unit: ::V1::Schemas::Enums::InventoryUnitEnum,
            quantity: {type: :string},
            quality: {type: [:integer, :null]},
            qualityMatch: ::V1::Schemas::Enums::FleetContractQualityMatchEnum,
            position: {type: :integer},
            # Paid per SCU or unit delivered against this line, on a per-unit
            # contract.
            rewardRate: {type: [:string, :null]},
            item: ::V1::Schemas::Contracts::FleetContractItemRef,
            # Present on a line asking for a crafted part only.
            crafted: ::V1::Schemas::InventoryCraftedRef,
            createdAt: {type: [:string, :null], format: "date-time"},
            updatedAt: {type: [:string, :null], format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name category unit quantity position qualityMatch rewardRate]
        })
      end
    end
  end
end
