# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanSummary
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              totals: ::V1::Schemas::Hangar::Plans::HangarPlanTotals,
              slots: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanSlotCost},
              issues: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanIssue}
            },
            additionalProperties: false,
            required: %w[totals slots issues]
          })
        end
      end
    end
  end
end
