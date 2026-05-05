# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventsList
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              items: {
                type: :array,
                items: {"$ref": "#/components/schemas/FleetEvent"}
              },
              meta: {"$ref": "#/components/schemas/Meta"}
            },
            required: %w[items meta]
          })
        end
      end
    end
  end
end
