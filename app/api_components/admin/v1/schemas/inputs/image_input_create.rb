# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ImageInputCreate < ImageInput
          include OpenapiRuby::Components::Base

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
