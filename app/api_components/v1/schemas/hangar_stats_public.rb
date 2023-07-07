# frozen_string_literal: true

module V1
  module Schemas
    class HangarStatsPublic
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          total: {type: :integer},
          classifications: {type: :array, items: {"$ref": "#/components/schemas/HangarClassificationMetric"}},
          groups: {type: :array, items: {"$ref": "#/components/schemas/HangarGroupMetric"}}
        },
        required: %w[total classifications groups]
      })
    end
  end
end
