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
            description: {type: [:string, :null]},
            signupApproval: {
              type: [:string, :null],
              enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS + [nil]
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
