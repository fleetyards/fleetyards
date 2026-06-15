# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSlotUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: :string},
            signupApproval: {
              type: :string,
                            enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
