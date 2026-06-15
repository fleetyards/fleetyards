# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSignupAssignInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fleetEventSlotId: {type: :string, format: :uuid},
            status: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEventSignup::STATUSES
            },
            vehicleId: {type: :string, format: :uuid},
            notes: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
