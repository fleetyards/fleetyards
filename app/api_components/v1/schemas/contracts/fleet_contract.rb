# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      class FleetContract
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            title: {type: :string},
            # The author's own title, when they gave one. `title` is this or the
            # sentence derived from the goods.
            customTitle: {type: [:string, :null]},
            slug: {type: :string},
            description: {type: [:string, :null]},
            kind: ::V1::Schemas::Enums::FleetContractKindEnum,
            state: ::V1::Schemas::Enums::FleetContractStateEnum,
            # decimal(15, 2) with no currency column -- aUEC is the only one,
            # and its name lives in a translation.
            reward: {type: :string},
            reimburseExpenses: {type: :boolean},
            crewLimit: {type: [:integer, :null]},
            # Only a transport contract has a collection leg to track, and the
            # client shows the pickup column on this rather than on the kind.
            requiresPickup: {type: :boolean},
            deadline: {type: [:string, :null], format: "date-time"},
            itemsCount: {type: :integer},
            crewCount: {type: :integer},
            source: ::V1::Schemas::Contracts::FleetContractEndpoint,
            destination: ::V1::Schemas::Contracts::FleetContractEndpoint,
            createdBy: ::V1::Schemas::Contracts::FleetContractAuthor,
            publishedAt: {type: [:string, :null], format: "date-time"},
            claimedAt: {type: [:string, :null], format: "date-time"},
            fulfilledAt: {type: [:string, :null], format: "date-time"},
            cancelledAt: {type: [:string, :null], format: "date-time"},
            expiredAt: {type: [:string, :null], format: "date-time"},
            createdAt: {type: [:string, :null], format: "date-time"},
            updatedAt: {type: [:string, :null], format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id title slug kind state reward requiresPickup destination itemsCount crewCount]
        })
      end
    end
  end
end
