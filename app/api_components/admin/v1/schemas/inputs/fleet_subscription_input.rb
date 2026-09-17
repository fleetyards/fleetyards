# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        # `grantedVia` is deliberately absent: everything opened here is a
        # manual grant, and letting an admin claim a row was seeded from a
        # contribution would hand it to the reconciler to close.
        class FleetSubscriptionInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              fleetId: {type: :string, format: :uuid},
              startedAt: {type: :string, format: :date},
              # Nullable so a closed subscription can be reopened by clearing
              # it, which is the shape a date field needs to be editable at all.
              endedAt: {type: [:string, :null], format: :date},
              note: {type: [:string, :null]},
              updateReason: {type: :string},
              updateReasonDescription: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
