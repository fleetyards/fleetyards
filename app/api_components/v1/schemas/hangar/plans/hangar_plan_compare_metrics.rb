# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanCompareMetrics
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              left: ::V1::Schemas::Hangar::Plans::HangarPlanMetrics,
              right: ::V1::Schemas::Hangar::Plans::HangarPlanMetrics
            },
            additionalProperties: false,
            required: %w[left right]
          })
        end
      end
    end
  end
end
