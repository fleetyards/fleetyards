# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleMoveInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            afterId: {type: :string, format: :uuid, description: "Place the vehicle right after this one of the owner's vehicles"},
            beforeId: {type: :string, format: :uuid, description: "Place the vehicle right before this one of the owner's vehicles"}
          },
          description: "Exactly one of afterId and beforeId",
          additionalProperties: false
        })
      end
    end
  end
end
