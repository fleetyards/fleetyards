# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # Read out of the transfer ledger on every request. Never stored, so it
      # cannot disagree with the entries it is a sum over.
      class FleetContractProgress
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            complete: {type: :boolean},
            fraction: {type: :number},
            lines: {
              type: :array,
              items: ::V1::Schemas::Contracts::FleetContractProgressLine
            },
            shares: {
              type: :array,
              items: ::V1::Schemas::Contracts::FleetContractShare
            }
          },
          additionalProperties: false,
          required: %w[complete fraction lines shares]
        })
      end
    end
  end
end
