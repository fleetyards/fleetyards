# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetVehiclesStats
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            total: {type: :integer},
            classifications: {type: :array, items: {"$ref": "#/components/schemas/HangarClassificationMetric"}},
            metrics: {"$ref": "#/components/schemas/HangarMetrics"}
          },
          additionalProperties: false,
          required: %w[total classifications metrics]
        })
      end
    end
  end
end
