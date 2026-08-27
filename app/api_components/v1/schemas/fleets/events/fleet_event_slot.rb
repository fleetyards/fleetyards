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
              slottableType: ::V1::Schemas::Enums::FleetEventSlottableTypeEnum,
              slottableId: {type: :string, format: :uuid},
              title: {type: :string},
              description: {type: :string},
              position: {type: :integer},
              derived: {type: :boolean},
              positionType: {type: :string},
              modelPositionId: {type: :string, format: :uuid},
              signupApproval: ::V1::Schemas::Enums::FleetEventSignupApprovalEnum,
              effectiveSignupApproval: ::V1::Schemas::Enums::FleetEventSignupApprovalEnum,
              signups: {
                type: :array,
                items: ::V1::Schemas::Fleets::Events::FleetEventSignup
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
