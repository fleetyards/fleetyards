# frozen_string_literal: true

module V1
  module Schemas
    class RoadmapWeek
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          value: {type: :integer},
          query: {
            type: :object,
            properties: {
              lastUpdatedAtGteq: {type: :string, format: "date"},
              lastUpdatedAtLt: {type: :string, format: "date"}
            }
          },
          label: {type: :string}
        },
        additionalProperties: false,
        required: %w[value query label]
      })
    end
  end
end
