# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetMemberQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            usernameCont: {type: :string},
            nameCont: {type: :string, deprecated: true, description: "Use usernameCont instead"},
            roleIn: {type: :array, items: {type: :string}},
            stateIn: {type: :array, items: {type: :string}},
            acceptedAtGteq: {type: :string, format: :date},
            acceptedAtLteq: {type: :string, format: :date},
            invitedAtGteq: {type: :string, format: :date},
            invitedAtLteq: {type: :string, format: :date},
            requestedAtGteq: {type: :string, format: :date},
            requestedAtLteq: {type: :string, format: :date},
            declinedAtGteq: {type: :string, format: :date},
            declinedAtLteq: {type: :string, format: :date},
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
