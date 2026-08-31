# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class AdminFleetMemberQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              usernameCont: {type: :string},
              stateEq: {type: :string},
              roleCont: {type: :string},
              s: {anyOf: [{
                type: :array, items: ::Shared::V1::Schemas::Sorts::FleetMembershipSortEnum
              }, ::Shared::V1::Schemas::Sorts::FleetMembershipSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Shared::V1::Schemas::Sorts::FleetMembershipSortEnum
              }, ::Shared::V1::Schemas::Sorts::FleetMembershipSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
