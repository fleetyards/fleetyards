# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class RaffleQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              titleCont: {type: :string},
              publishedEq: {type: :boolean},
              s: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::RaffleSortEnum
              }, ::Admin::V1::Schemas::Sorts::RaffleSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::RaffleSortEnum
              }, ::Admin::V1::Schemas::Sorts::RaffleSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
