# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelPositionInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              modelId: {type: :string, format: :uuid},
              name: {type: :string},
              positionType: {type: :string},
              source: {type: :string},
              position: {type: :integer},
              hardpointId: {type: :string, format: :uuid, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
