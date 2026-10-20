# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            description: {type: [:string, :null]},
            startingCredit: {type: :number, minimum: 0},
            source: ::V1::Schemas::Enums::HangarPlanSourceEnum,
            sourcePlanId: {type: [:string, :null], format: :uuid}
          },
          required: %w[name],
          additionalProperties: false
        })
      end
    end
  end
end
