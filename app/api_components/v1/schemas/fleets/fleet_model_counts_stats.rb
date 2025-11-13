# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetModelCountsStats
        include Rswag::SchemaComponents::Component

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
end
