# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Missions
        class MissionShip
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              missionTeamId: {type: :string, format: :uuid},
              title: {type: :string, nullable: true},
              displayTitle: {type: :string, nullable: true},
              description: {type: :string, nullable: true},
              position: {type: :integer},
              strict: {type: :boolean},
              model: {
                type: :object,
                nullable: true,
                properties: {
                  id: {type: :string, format: :uuid},
                  name: {type: :string},
                  slug: {type: :string},
                  image: {"$ref": "#/components/schemas/MediaFile", nullable: true}
                },
                required: %w[id name slug]
              },
              filters: {
                type: :object,
                properties: {
                  classification: {type: :string, nullable: true},
                  focus: {type: :string, nullable: true},
                  minSize: {type: :string, nullable: true},
                  maxSize: {type: :string, nullable: true},
                  minCrew: {type: :integer, nullable: true},
                  minCargo: {type: :number, nullable: true}
                }
              },
              slots: {
                type: :array,
                items: {"$ref": "#/components/schemas/MissionSlot"}
              }
            },
            required: %w[id missionTeamId position strict slots],
            additionalProperties: false
          })
        end
      end
    end
  end
end
