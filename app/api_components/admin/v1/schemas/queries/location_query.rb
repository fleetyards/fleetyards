# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class LocationQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              scKeyCont: {type: :string},
              slugCont: {type: :string},
              idIn: {type: :array, items: {type: :string, format: :uuid}},
              nameIn: {type: :array, items: {type: :string}},
              kindEq: ::Shared::V1::Schemas::Enums::LocationKindEnum,
              kindIn: {type: :array, items: ::Shared::V1::Schemas::Enums::LocationKindEnum},
              parentIdEq: {type: :string, format: :uuid},
              systemIdEq: {type: :string, format: :uuid},
              shownOnStarmapEq: {type: :boolean},
              # Off by default here: a retired place is one of the things the
              # section is for.
              currentVersion: {type: :boolean},
              s: ::Admin::V1::Schemas::Sorts::LocationSortEnum,
              sorts: {type: :array, items: ::Admin::V1::Schemas::Sorts::LocationSortEnum}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
