# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetSquadronMemberQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: FleetMemberQuery::FILTERS.merge(
            squadronMembershipCreatedAtGteq: {type: :string, format: :date},
            squadronMembershipCreatedAtLteq: {type: :string, format: :date},
            s: {anyOf: [{
              type: :array, items: ::V1::Schemas::Sorts::FleetSquadronMemberSortEnum
            }, ::V1::Schemas::Sorts::FleetSquadronMemberSortEnum]},
            sorts: {anyOf: [{
              type: :array, items: ::V1::Schemas::Sorts::FleetSquadronMemberSortEnum
            }, ::V1::Schemas::Sorts::FleetSquadronMemberSortEnum]}
          ),
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
