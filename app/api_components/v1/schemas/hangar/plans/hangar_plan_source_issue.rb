# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanSourceIssue
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              kind: ::V1::Schemas::Enums::HangarPlanSourceIssueKindEnum,
              recordId: {type: :string, format: :uuid},
              plannedModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              currentModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel
            },
            additionalProperties: false,
            required: %w[kind recordId plannedModel]
          })
        end
      end
    end
  end
end
