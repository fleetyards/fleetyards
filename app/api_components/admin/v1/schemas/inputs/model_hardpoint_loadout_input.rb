# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelHardpointLoadoutInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              name: {type: :string, nullable: true},
              componentId: {type: :string, format: :uuid, nullable: true},
              modelHardpointId: {type: :string, format: :uuid, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
