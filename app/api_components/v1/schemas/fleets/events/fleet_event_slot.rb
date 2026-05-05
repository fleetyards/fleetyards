# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventSlot
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              slottableType: {type: :string, enum: %w[FleetEventTeam FleetEventShip]},
              slottableId: {type: :string, format: :uuid},
              title: {type: :string},
              description: {type: :string, nullable: true},
              position: {type: :integer},
              derived: {type: :boolean},
              positionType: {type: :string, nullable: true},
              modelPositionId: {type: :string, format: :uuid, nullable: true},
              signupApproval: {
                type: :string,
                nullable: true,
                enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS + [nil]
              },
              effectiveSignupApproval: {
                type: :string,
                enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS
              },
              signups: {
                type: :array,
                items: {"$ref": "#/components/schemas/FleetEventSignup"}
              }
            },
            required: %w[id slottableType slottableId title position derived effectiveSignupApproval signups],
            additionalProperties: false
          })
        end
      end
    end
  end
end
