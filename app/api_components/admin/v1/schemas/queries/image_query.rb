# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ImageQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              galleryIdEq: {type: :string, format: :uuid},
              galleryTypeEq: {type: :string}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
