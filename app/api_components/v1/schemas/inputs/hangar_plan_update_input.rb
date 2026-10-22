# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            description: {type: [:string, :null]},
            startingCredit: {type: :number, minimum: 0},
            vatRate: {type: [:number, :null], minimum: 0, maximum: 100},
            buybackTokens: {type: [:integer, :null], minimum: 0}
          },
          additionalProperties: false
        })
      end
    end
  end
end
