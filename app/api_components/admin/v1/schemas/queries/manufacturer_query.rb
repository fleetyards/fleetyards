# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ManufacturerQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              withModels: {type: :boolean},
              logoBlank: {type: :boolean},
              nameEq: {type: :string},
              nameCont: {type: :string},
              nameIn: {type: :array, items: {type: :string}},
              slugEq: {type: :string},
              slugCont: {type: :string},
              slugIn: {type: :array, items: {type: :string}},

              # The select resolves a value it was handed but has not paged to
              # yet, and it hands back whichever attribute it was told to use.
              idEq: {type: :string, format: :uuid},
              idIn: {type: :array, items: {type: :string, format: :uuid}},

              s: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::ManufacturerSortEnum
              }, ::Admin::V1::Schemas::Sorts::ManufacturerSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::ManufacturerSortEnum
              }, ::Admin::V1::Schemas::Sorts::ManufacturerSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
