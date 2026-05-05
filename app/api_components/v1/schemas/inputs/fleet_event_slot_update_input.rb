# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSlotUpdateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: :string, nullable: true},
            signupApproval: {
              type: :string,
              nullable: true,
              enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS + [nil]
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
