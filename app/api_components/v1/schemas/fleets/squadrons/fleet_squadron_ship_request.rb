# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadronShipRequest
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              member: ::V1::Schemas::Fleets::FleetMember,
              requestedByUsername: {type: [:string, :null]},
              vehicle: ::V1::Schemas::Fleets::Squadrons::FleetSquadronVehicle,
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id member requestedByUsername vehicle createdAt updatedAt]
          })
        end
      end
    end
  end
end
