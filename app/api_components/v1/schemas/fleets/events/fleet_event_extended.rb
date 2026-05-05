# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventExtended
          include Rswag::SchemaComponents::Component

          schema({
            allOf: [
              {"$ref": "#/components/schemas/FleetEvent"},
              {
                type: :object,
                properties: {
                  teams: {
                    type: :array,
                    items: {"$ref": "#/components/schemas/FleetEventTeam"}
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
