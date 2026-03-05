# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class VideoInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              modelId: {type: :string, format: :uuid},
              url: {type: :string},
              videoType: {"$ref": "#/components/schemas/VideoTypeEnum"}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
