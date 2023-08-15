# frozen_string_literal: true

module V1
  module Schemas
    class FleetModelCountsStats
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          modelCounts: {
            type: :object,
            additionalProperties: {
              type: :integer
            }
          }
        },
        additionalProperties: false,
        required: %w[modelCounts]
      })
    end
  end
end
