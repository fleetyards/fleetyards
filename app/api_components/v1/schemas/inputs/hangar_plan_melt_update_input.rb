# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanMeltUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            valueOverride: {type: [:number, :null], minimum: 0}
          },
          additionalProperties: false
        })
      end
    end
  end
end
