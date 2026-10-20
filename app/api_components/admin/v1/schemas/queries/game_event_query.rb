# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class GameEventQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              titleCont: {type: :string},
              categoryEq: ::Admin::V1::Schemas::Enums::GameEventCategoryEnum,
              publishedEq: {type: :boolean},
              startsAtGteq: {type: :string, format: "date-time"},
              startsAtLteq: {type: :string, format: "date-time"},
              s: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::GameEventSortEnum
              }, ::Admin::V1::Schemas::Sorts::GameEventSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::GameEventSortEnum
              }, ::Admin::V1::Schemas::Sorts::GameEventSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
