# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class VehicleQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              searchCont: {type: :string},
              idEq: {type: :string},
              idIn: {type: :array, items: {type: :string}},
              idNotIn: {type: :array, items: {type: :string}},
              nameCont: {type: :string},
              nameIn: {type: :array, items: {type: :string}},
              userUsernameIn: {type: :array, items: {type: :string}},
              modelSlugIn: {type: :array, items: {type: :string}},
              manufacturerIn: {type: :array, items: {type: :string}},
              modelIdEq: {type: :string},
              modelIdIn: {type: :array, items: {type: :string}},
              modelIdNotIn: {type: :array, items: {type: :string}},
              modelNameCont: {type: :string},
              modelNameIn: {type: :array, items: {type: :string}},
              modelProductionStatusIn: {type: :array, items: {type: :string}},
              modelSearchCont: {type: :string},
              loanerEq: ::Shared::V1::Schemas::Enums::LoanerFilterEnum,
              wantedEq: {type: :boolean},
              s: {anyOf: [{
                type: :array, items: ::Shared::V1::Schemas::Sorts::VehicleSortEnum
              }, ::Shared::V1::Schemas::Sorts::VehicleSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Shared::V1::Schemas::Sorts::VehicleSortEnum
              }, ::Shared::V1::Schemas::Sorts::VehicleSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
