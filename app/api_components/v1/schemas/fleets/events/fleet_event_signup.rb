# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventSignup
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventId: {type: :string, format: :uuid},
              fleetEventSlotId: {type: :string, format: :uuid},
              occurrenceDate: {type: :string, format: :date},
              status: {"$ref": "#/components/schemas/FleetEventSignupStatusEnum"},
              notes: {type: :string},
              confirmedAt: {type: :string, format: "date-time"},
              withdrawnAt: {type: :string, format: "date-time"},
              user: Shared::V1::Schemas::UserRef,
              vehicle: FleetEventSignupVehicle
            },
            required: %w[id fleetEventId status],
            additionalProperties: false
          })
        end
      end
    end
  end
end
