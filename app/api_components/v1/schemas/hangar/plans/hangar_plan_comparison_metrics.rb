# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanComparisonMetrics
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              live: ::V1::Schemas::Hangar::Plans::HangarPlanMetrics,
              plan: ::V1::Schemas::Hangar::Plans::HangarPlanMetrics
            },
            additionalProperties: false,
            required: %w[live plan]
          })
        end
      end
    end
  end
end
