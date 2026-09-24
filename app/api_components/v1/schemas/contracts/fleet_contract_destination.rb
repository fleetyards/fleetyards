# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # An inventory a contract can deliver into, as a picker offers it. The
      # holder says which id field a contract form sends it back in.
      class FleetContractDestination
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
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
