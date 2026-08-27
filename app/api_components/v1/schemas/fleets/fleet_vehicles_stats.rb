# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetVehiclesStats
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            total: {type: :integer},
            classifications: {type: :array, items: ::V1::Schemas::Hangar::HangarClassificationMetric},
            metrics: ::V1::Schemas::Hangar::HangarMetrics
          },
          additionalProperties: false,
          required: %w[total classifications metrics]
        })
      end
    end
  end
end
