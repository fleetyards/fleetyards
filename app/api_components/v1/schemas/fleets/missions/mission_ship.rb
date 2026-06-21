# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Missions
        class MissionShip
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              missionTeamId: {type: :string, format: :uuid},
              title: {type: :string},
              displayTitle: {type: :string},
              description: {type: :string},
              position: {type: :integer},
              strict: {type: :boolean},
              model: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  name: {type: :string},
                  slug: {type: :string},
                  minCrew: {type: :integer},
                  maxCrew: {type: :integer},
                  image: {"$ref": "#/components/schemas/MediaFile"}
                },
                required: %w[id name slug]
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
