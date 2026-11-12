# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventTeamCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: [:string, :null]},
            fleetSquadronId: {type: [:string, :null], format: :uuid},
            sourceFlightId: {type: [:string, :null], format: :uuid}
          },
          required: %w[title],
          additionalProperties: false
        })
      end
    end
  end
end
