# frozen_string_literal: true

module V1
  module Schemas
    class RoadmapItem < RoadmapItemBase
      include SchemaConcern

      schema({
        properties: {
          model: {"$ref": "#/components/schemas/ModelMinimal"},
          lastVersionChangedAt: {type: :string, format: "date-time"},
          lastVersionChangedAtLabel: {type: :string},
          lastVersion: {type: :string},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[
          lastVersionChangedAt lastVersionChangedAtLabel createdAt updatedAt
        ]
      })
    end
  end
end
