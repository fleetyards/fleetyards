# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FleetSubscription
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            startedAt: {type: :string, format: :date},
            endedAt: {type: :string, format: :date},
            grantedVia: ::Admin::V1::Schemas::Enums::FleetSubscriptionGrantedViaEnum,
            note: {type: :string},
            # Whether it is still open, and whether it grants *today*. They
            # differ on a subscription that has not started yet.
            open: {type: :boolean},
            active: {type: :boolean},
            fleet: ::Admin::V1::Schemas::Fleets::Options::FleetOption,
            supporterContributionId: {type: :string, format: :uuid},
            supporterContribution: ::Admin::V1::Schemas::FleetSubscriptionContribution,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id startedAt grantedVia open active fleet],
          additionalProperties: false
        })
      end
    end
  end
end
