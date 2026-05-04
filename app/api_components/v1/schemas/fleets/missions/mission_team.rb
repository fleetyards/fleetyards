# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Missions
        class MissionTeam
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              missionId: {type: :string, format: :uuid},
              title: {type: :string},
              description: {type: :string, nullable: true},
              position: {type: :integer},
              slots: {
                type: :array,
                items: {"$ref": "#/components/schemas/MissionSlot"}
              },
              ships: {
                type: :array,
                items: {"$ref": "#/components/schemas/MissionShip"}
              }
            },
            required: %w[id missionId title position slots ships],
            additionalProperties: false
          })
        end
      end
    end
  end
end
