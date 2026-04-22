# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class VideoQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              modelIdEq: {type: :string, format: :uuid},
              videoTypeEq: {"$ref": "#/components/schemas/VideoTypeEnum"}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
