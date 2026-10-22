# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanCandidateCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slotId: {type: :string, format: :uuid},
            modelId: {type: :string, format: :uuid},
            modelPaintId: {type: [:string, :null], format: :uuid},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}}
          },
          required: %w[slotId modelId],
          additionalProperties: false
        })
      end
    end
  end
end
