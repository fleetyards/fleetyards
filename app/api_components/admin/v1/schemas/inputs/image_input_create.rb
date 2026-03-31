# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ImageInputCreate < ImageInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              file: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
