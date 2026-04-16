# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarStatsPublic
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            total: {type: :integer},
            wishlistTotal: {type: :integer},
            classifications: {type: :array, items: {"$ref": "#/components/schemas/HangarClassificationMetric"}},
            groups: {type: :array, items: {"$ref": "#/components/schemas/HangarGroupMetric"}},
            metrics: {"$ref": "#/components/schemas/HangarMetricsPublic"}
          },
          additionalProperties: false,
          required: %w[total classifications groups metrics]
        })
      end
    end
  end
end
