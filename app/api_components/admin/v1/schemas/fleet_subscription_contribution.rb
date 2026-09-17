# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # Enough of the contribution behind a subscription to say who paid and
      # how much, without repeating the whole record. Absent on a comp, which
      # is how an admin tells the two apart at a glance.
      class FleetSubscriptionContribution
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            amountCents: {type: :integer},
            currency: {type: :string},
            displayName: {type: :string}
          },
          required: %w[id amountCents currency displayName],
          additionalProperties: false
        })
      end
    end
  end
end
