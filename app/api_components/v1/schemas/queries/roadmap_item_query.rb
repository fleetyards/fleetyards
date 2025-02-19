# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class RoadmapItemQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            releasedEq: {type: :boolean},
            updatedAtGteq: {type: :string, format: "date-time"},
            updatedAtLteq: {type: :string, format: "date-time"},
            lastUpdatedAtLteq: {type: :string, format: "date-time"},
            lastUpdatedAtGteq: {type: :string, format: "date-time"},
            activeEq: {type: :boolean},
            lastUpdatedAtLt: {type: :string, format: "date-time"},
            rsiReleaseIdGteq: {type: :string, format: "date-time"},
            rsiCategoryIdIn: {type: :array, items: {type: :string}},
            activeIn: {type: :array, items: {type: :boolean}},
            sorts: {anyOf: [{
              type: :array, items: {"$ref": "#/components/schemas/RoadmapItemSortEnum"}
            }, {
              "$ref": "#/components/schemas/RoadmapItemSortEnum"
            }]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
