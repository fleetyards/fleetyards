# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanCandidateUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            modelPaintId: {type: [:string, :null], format: :uuid},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
