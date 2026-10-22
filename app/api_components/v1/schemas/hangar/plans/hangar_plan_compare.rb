# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanCompare
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              otherPlanId: {type: :string, format: :uuid},
              otherPlanName: {type: :string},
              models: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanModelDiff},
              totals: ::V1::Schemas::Hangar::Plans::HangarPlanCompareTotals,
              metrics: ::V1::Schemas::Hangar::Plans::HangarPlanCompareMetrics
            },
            additionalProperties: false,
            required: %w[otherPlanId otherPlanName models totals metrics]
          })
        end
      end
    end
  end
end
