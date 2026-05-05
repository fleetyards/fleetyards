# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventTeam
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventId: {type: :string, format: :uuid},
              title: {type: :string},
              description: {type: :string, nullable: true},
              position: {type: :integer},
              slots: {
                type: :array,
                items: {"$ref": "#/components/schemas/FleetEventSlot"}
              },
              ships: {
                type: :array,
                items: {"$ref": "#/components/schemas/FleetEventShip"}
              }
            },
            required: %w[id fleetEventId title position slots ships],
            additionalProperties: false
          })
        end
      end
    end
  end
end
