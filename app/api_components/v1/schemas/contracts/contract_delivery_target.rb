# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # A contract the reader is working, and where its goods go. What a
      # transfer form offers as a target: sending there files the transfer
      # under the contract.
      class ContractDeliveryTarget
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            contractId: {type: :string, format: :uuid},
            contractTitle: {type: :string},
            contractSlug: {type: :string},
            fleetSlug: {type: :string},
            fleetName: {type: :string},
            destination: ::V1::Schemas::Contracts::FleetContractDestination
          },
          additionalProperties: false,
          required: %w[contractId contractTitle contractSlug fleetSlug fleetName destination]
        })
      end
    end
  end
end
