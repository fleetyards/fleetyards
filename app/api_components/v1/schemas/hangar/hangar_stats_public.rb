# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarStatsPublic
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            total: {type: :integer},
            classifications: {type: :array, items: {"$ref": "#/components/schemas/HangarClassificationMetric"}},
            groups: {type: :array, items: {"$ref": "#/components/schemas/HangarGroupMetric"}}
          },
          additionalProperties: false,
          required: %w[total classifications groups]
        })
      end
    end
  end
end
