# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventSlot
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              slottableType: {type: :string, enum: %w[FleetEventTeam FleetEventShip]},
              slottableId: {type: :string, format: :uuid},
              title: {type: :string},
              description: {type: :string},
              position: {type: :integer},
              derived: {type: :boolean},
              positionType: {type: :string},
              modelPositionId: {type: :string, format: :uuid},
              signupApproval: {
                type: :string,
                                enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS
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
