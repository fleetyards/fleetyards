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
              description: {type: [:string, :null]},
              position: {type: :integer},
              teamId: {type: :string, format: :uuid},
              slots: {type: :array, items: ::V1::Schemas::Fleets::Missions::MissionSlot},
              ships: {type: :array, items: ::V1::Schemas::Fleets::Missions::MissionShip},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name description position teamId slots ships createdAt updatedAt]
          })
        end
      end
    end
  end
end
