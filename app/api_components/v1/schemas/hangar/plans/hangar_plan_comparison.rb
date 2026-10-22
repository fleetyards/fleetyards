# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanComparison
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              vehicles: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanVehicleStatus},
              models: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanModelDiff},
              gaps: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanGap},
              metrics: ::V1::Schemas::Hangar::Plans::HangarPlanComparisonMetrics
            },
            additionalProperties: false,
            required: %w[vehicles models gaps metrics]
          })
        end
      end
    end
  end
end
