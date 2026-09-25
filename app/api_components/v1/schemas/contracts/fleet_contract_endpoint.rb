# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # One of a contract's two inventory ends. Null on the source of anything
      # but a transport contract, and on either end once that inventory was
      # deleted -- the foreign keys are ON DELETE SET NULL. Only the destination
      # can be the author's own inventory.
      class FleetContractEndpoint
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            location: {type: [:string, :null]},
            holder: ::V1::Schemas::Enums::FleetContractDestinationHolderEnum
          },
          additionalProperties: false,
          required: %w[id name slug holder]
        })
      end
    end
  end
end
