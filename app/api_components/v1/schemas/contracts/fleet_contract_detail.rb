# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # One contract with everything the detail page draws. Separate from the
      # list shape rather than optional fields on it: the list renders hundreds
      # of these and computes no progress for any of them.
      class FleetContractDetail < ::V1::Schemas::Contracts::FleetContract
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {
              type: :array,
              items: ::V1::Schemas::Contracts::FleetContractItem
            },
            crew: {
              type: :array,
              items: ::V1::Schemas::Contracts::FleetContractCrewMember
            },
            progress: ::V1::Schemas::Contracts::FleetContractProgress
          },
          required: %w[items crew progress]
        })
      end
    end
  end
end
