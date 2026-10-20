# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanSlotChooseInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            candidateId: {type: :string, format: :uuid}
          },
          required: %w[candidateId],
          additionalProperties: false
        })
      end
    end
  end
end
