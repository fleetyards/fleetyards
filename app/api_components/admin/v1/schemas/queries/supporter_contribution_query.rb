# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class SupporterContributionQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              nameEq: {type: :string},
              recurringEq: {type: :boolean},
              anonymousEq: {type: :boolean},
              sourceEq: {"$ref": "#/components/schemas/SupporterContributionSourceEnum"},
              startedAtGteq: {type: :string, format: :date},
              startedAtLteq: {type: :string, format: :date},
              endedAtGteq: {type: :string, format: :date},
              endedAtLteq: {type: :string, format: :date},
              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/SupporterContributionSortEnum"}
              }, {
                "$ref": "#/components/schemas/SupporterContributionSortEnum"
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
