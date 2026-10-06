# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class FleetQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              fidCont: {type: :string},
              search: {type: :string, description: "Name or SID, ranked exact, then prefix, then contains"},
              memberCountGteq: {type: :integer, description: "Accepted members"},
              memberCountLteq: {type: :integer, description: "Accepted members"},
              rsiVerifiedEq: {type: :boolean},
              publicFleetEq: {type: :boolean},
              recruitingEq: {type: :boolean},
              createdOnGteq: {type: :string, format: :date},
              createdOnLteq: {type: :string, format: :date},
              s: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::FleetSortEnum
              }, ::Admin::V1::Schemas::Sorts::FleetSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::FleetSortEnum
              }, ::Admin::V1::Schemas::Sorts::FleetSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
