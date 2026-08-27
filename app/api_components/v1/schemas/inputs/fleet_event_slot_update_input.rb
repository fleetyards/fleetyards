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
            signupApproval: ::V1::Schemas::Enums::NullableFleetEventSignupApprovalEnum
          },
          additionalProperties: false
        })
      end
    end
  end
end
