# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventShip
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventTeamId: {type: :string, format: :uuid},
              title: {type: :string},
              displayTitle: {type: :string},
              description: {type: :string},
              position: {type: :integer},
              strict: {type: :boolean},
              model: {"$ref": "#/components/schemas/ShipModel"},
              # The models a spot will take when it names several rather than
              # one; empty for the other two kinds of spot.
              allowedModels: {
                type: :array,
                items: {"$ref": "#/components/schemas/ShipModel"}
              },
              filters: {
                type: :object,
                properties: {
                  classification: {type: :string},
                  focus: {type: :string},
                  minSize: {type: :string},
                  maxSize: {type: :string},
                  minCrew: {type: :integer},
                  minCargo: {type: :number}
                }
              },
              slots: {
                type: :array,
                items: {"$ref": "#/components/schemas/FleetEventSlot"}
              }
            },
            required: %w[id fleetEventTeamId position strict allowedModels slots],
            additionalProperties: false
          })
        end
      end
    end
  end
end
