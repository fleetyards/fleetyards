# frozen_string_literal: true

module V1
  module Schemas
    class HangarStats
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          total: {type: :integer},
          wishlistTotal: {type: :integer},
          classifications: {type: :array, items: {"$ref": "#/components/schemas/HangarClassificationMetric"}},
          groups: {type: :array, items: {"$ref": "#/components/schemas/HangarGroupMetric"}},
          metrics: {"$ref": "#/components/schemas/HangarMetrics"}
        },
        required: %w[total wishlistTotal classifications groups metrics]
      })
    end
  end
end
