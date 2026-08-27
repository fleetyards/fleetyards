# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMembersStats
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            total: {type: :integer},
            metrics: FleetMembersMetrics
          },
          additionalProperties: false,
          required: %w[total metrics]
        })
      end
    end
  end
end
