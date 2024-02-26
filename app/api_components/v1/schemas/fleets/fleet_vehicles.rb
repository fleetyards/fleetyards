# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetVehicles < ::Shared::V1::Schemas::BaseList
        include SchemaConcern

        schema({
          properties: {
            items: {type: :array, items: {
              oneOf: [
                {"$ref": "#/components/schemas/Model"},
                {"$ref": "#/components/schemas/VehiclePublic"}
              ]
            }}
          },
          required: %w[items]
        })
      end
    end
  end
end
