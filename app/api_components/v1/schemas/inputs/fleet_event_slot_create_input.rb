# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSlotCreateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            slottableType: {type: :string, enum: %w[FleetEventTeam FleetEventShip]},
            slottableId: {type: :string, format: :uuid},
            title: {type: :string},
            description: {type: :string, nullable: true},
            signupApproval: {
              type: :string,
              nullable: true,
              enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS + [nil]
            }
          },
          required: %w[slottableType slottableId title],
          additionalProperties: false
        })
      end
    end
  end
end
