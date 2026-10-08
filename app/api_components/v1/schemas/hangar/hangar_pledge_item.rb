# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarPledgeItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            rsiPledgeId: {type: :string},
            kind: ::V1::Schemas::Enums::HangarPledgeItemKindEnum,
            name: {type: :string},
            quantity: {type: :integer, description: "How often the pledge lists the item"},
            image: {type: :string, format: :uri},
            standalone: {type: :boolean, description: "Whether the item is all its pledge holds"},
            meltable: {type: :boolean, description: "Whether RSI offers to melt the item's pledge"},
            pledgeCreatedOn: {type: :string, format: :date},
            meltValue: {type: :number, description: "What melting the item returns, in USD; only for an item that is its whole pledge"},
            pledgeName: {type: :string},
            pledgeValue: {type: :number, description: "What melting the whole pledge returns, in USD"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id rsiPledgeId kind name quantity standalone meltable createdAt updatedAt]
        })
      end
    end
  end
end
