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
            # What running the mission unlocks for each crew member. Earned in
            # game, never paid out by the fleet.
            missionBlueprints: {
              type: :array,
              items: ::Shared::V1::Schemas::GameMissionBlueprint
            },
            crew: {
              type: :array,
              items: ::V1::Schemas::Contracts::FleetContractCrewMember
            },
            progress: ::V1::Schemas::Contracts::FleetContractProgress
          },
          required: %w[items missionBlueprints crew progress]
        })
      end
    end
  end
end
