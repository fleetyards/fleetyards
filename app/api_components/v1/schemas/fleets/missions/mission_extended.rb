# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Missions
        class MissionExtended
          include Rswag::SchemaComponents::Component

          schema({
            allOf: [
              {"$ref": "#/components/schemas/Mission"},
              {
                type: :object,
                properties: {
                  teams: {
                    type: :array,
                    items: {"$ref": "#/components/schemas/MissionTeam"}
                  }
                },
                required: %w[teams]
              }
            ]
          })
        end
      end
    end
  end
end
