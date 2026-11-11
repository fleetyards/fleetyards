# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadronSlotCandidate
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              position: {type: :integer},
              username: {type: [:string, :null]},
              avatar: ::Shared::V1::Schemas::MediaFile,
              passedAt: {type: [:string, :null], format: "date-time"},
              vehicle: {anyOf: [::V1::Schemas::Fleets::Squadrons::FleetSquadronVehicle, {type: :null}]}
            },
            additionalProperties: false,
            required: %w[id position username passedAt vehicle]
          })
        end
      end
    end
  end
end
