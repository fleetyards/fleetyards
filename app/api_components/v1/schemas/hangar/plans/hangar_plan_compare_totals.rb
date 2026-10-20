# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanCompareTotals
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              left: ::V1::Schemas::Hangar::Plans::HangarPlanTotals,
              right: ::V1::Schemas::Hangar::Plans::HangarPlanTotals
            },
            additionalProperties: false,
            required: %w[left right]
          })
        end
      end
    end
  end
end
