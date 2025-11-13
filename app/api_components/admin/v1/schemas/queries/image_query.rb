# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ImageQuery
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              galleryIdEq: {type: :string, format: :uuid},
              galleryTypeEq: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
