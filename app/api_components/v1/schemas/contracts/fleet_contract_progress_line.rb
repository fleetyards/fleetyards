# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      class FleetContractProgressLine
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            itemId: {type: :string, format: :uuid},
            name: {type: :string},
            # The catalogue record the line asks for, so the line can link to
            # it. Absent for a line somebody typed by hand.
            item: ::V1::Schemas::Contracts::FleetContractItemRef,
            category: ::V1::Schemas::Enums::InventoryCategoryEnum,
            unit: ::V1::Schemas::Enums::InventoryUnitEnum,
            quality: {type: [:integer, :null]},
            qualityMatch: ::V1::Schemas::Enums::FleetContractQualityMatchEnum,
            requested: {type: :string},
            delivered: {type: :string},
            # Out of the source inventory and into the contractor's hold. Always
            # zero on a contract with no collection leg.
            pickedUp: {type: :string},
            remaining: {type: :string},
            complete: {type: :boolean},
            fraction: {type: :number},
            contributions: {
              type: :array,
              items: ::V1::Schemas::Contracts::FleetContractContribution
            }
          },
          additionalProperties: false,
          required: %w[itemId name category unit requested delivered pickedUp remaining complete fraction contributions]
        })
      end
    end
  end
end
