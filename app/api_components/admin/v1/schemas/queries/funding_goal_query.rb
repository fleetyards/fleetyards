# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class FundingGoalQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              titleCont: {type: :string},
              effectiveFromGteq: {type: :string, format: :date},
              effectiveFromLteq: {type: :string, format: :date},
              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/FundingGoalSortEnum"}
              }, {
                "$ref": "#/components/schemas/FundingGoalSortEnum"
              }]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
