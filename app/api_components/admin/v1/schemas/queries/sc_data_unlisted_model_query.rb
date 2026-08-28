# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ScDataUnlistedModelQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              identifierCont: {type: :string},
              nameCont: {type: :string},
              comparisonEq: ::Admin::V1::Schemas::Enums::UnlistedModelComparisonEnum,
              manufacturerCodeEq: {type: :string},

              # The list is the undecided ones unless one of these asks
              # otherwise: `decisionEq` for a single kind, `decisionNull=false`
              # for everything already dealt with.
              decisionEq: ::Admin::V1::Schemas::Enums::UnlistedModelDecisionEnum,
              decisionNull: {type: :boolean},

              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::ScDataUnlistedModelSortEnum
              }, ::Admin::V1::Schemas::Sorts::ScDataUnlistedModelSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
