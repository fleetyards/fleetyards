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
              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/FleetMembershipSortEnum"}
              }, {
                "$ref": "#/components/schemas/FleetMembershipSortEnum"
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
