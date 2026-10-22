# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanMeltCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            vehicleId: {type: :string, format: :uuid},
            valueOverride: {type: [:number, :null], minimum: 0}
          },
          required: %w[vehicleId],
          additionalProperties: false
        })
      end
    end
  end
end
