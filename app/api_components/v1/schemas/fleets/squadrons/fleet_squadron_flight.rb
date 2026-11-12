# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadronFlight
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              shortDescription: {type: [:string, :null]},
              description: {type: [:string, :null]},
              position: {type: :integer},
              teamId: {type: :string, format: :uuid},
              coverImage: {anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]},
              slots: {type: :array, items: ::V1::Schemas::Fleets::Missions::MissionSlot},
              ships: {type: :array, items: ::V1::Schemas::Fleets::Missions::MissionShip},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name shortDescription description position teamId coverImage slots ships createdAt updatedAt]
          })
        end
      end
    end
  end
end
