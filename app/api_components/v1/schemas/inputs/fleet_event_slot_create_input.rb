# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSlotCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slottableType: {"$ref": "#/components/schemas/FleetEventSlottableTypeEnum"},
            slottableId: {type: :string, format: :uuid},
            title: {type: :string},
            description: {type: [:string, :null]},
            signupApproval: {"$ref": "#/components/schemas/NullableFleetEventSignupApprovalEnum"}
          },
          required: %w[slottableType slottableId title],
          additionalProperties: false
        })
      end
    end
  end
end
