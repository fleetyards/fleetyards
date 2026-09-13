# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # One contractor's slice of the reward, derived from what they delivered
      # rather than agreed. `share` sums to 1 across the list.
      class FleetContractShare
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            userId: {type: :string, format: :uuid},
            weight: {type: :number},
            share: {type: :number}
          },
          additionalProperties: false,
          required: %w[userId weight share]
        })
      end
    end
  end
end
