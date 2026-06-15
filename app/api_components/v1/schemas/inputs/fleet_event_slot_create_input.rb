# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSlotCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slottableType: {type: :string, enum: %w[FleetEventTeam FleetEventShip]},
            slottableId: {type: :string, format: :uuid},
            title: {type: :string},
            description: {type: :string},
            signupApproval: {
              type: :string,
                            enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS
            }
          },
          required: %w[slottableType slottableId title],
          additionalProperties: false
        })
      end
    end
  end
end
