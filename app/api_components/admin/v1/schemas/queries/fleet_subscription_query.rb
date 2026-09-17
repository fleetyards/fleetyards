# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class FleetSubscriptionQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              fleetIdEq: {type: :string, format: :uuid},
              fleetNameCont: {type: :string},
              fleetSlugEq: {type: :string},
              grantedViaEq: ::Admin::V1::Schemas::Enums::FleetSubscriptionGrantedViaEnum,
              # Open is "no end date", so it is a null predicate rather than a
              # value -- the same shape userIdNull uses on contributions.
              endedAtNull: {type: :boolean},
              supporterContributionIdNull: {type: :boolean},
              startedAtGteq: {type: :string, format: :date},
              startedAtLteq: {type: :string, format: :date},
              s: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::FleetSubscriptionSortEnum
              }, ::Admin::V1::Schemas::Sorts::FleetSubscriptionSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::FleetSubscriptionSortEnum
              }, ::Admin::V1::Schemas::Sorts::FleetSubscriptionSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
