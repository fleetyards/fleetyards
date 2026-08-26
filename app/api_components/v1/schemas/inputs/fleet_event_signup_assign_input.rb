# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSignupAssignInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fleetEventSlotId: {type: [:string, :null], format: :uuid},
            status: {"$ref": "#/components/schemas/FleetEventSignupStatusEnum"},
            vehicleId: {type: [:string, :null], format: :uuid},
            notes: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
