# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSignupCreateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            status: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEventSignup::STATUSES
            },
            vehicleId: {type: :string, format: :uuid, nullable: true},
            notes: {type: :string, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
