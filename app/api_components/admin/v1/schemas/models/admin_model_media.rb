# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        # The admin payload adds a few internal images to the public set. A $ref
        # cannot be merged into, so the extra properties inherit the shared
        # component rather than being merged into the property that points at it.
        class AdminModelMedia < ::Shared::V1::Schemas::ModelMedia
          include OpenapiRuby::Components::Base

          schema({
            properties: {
              fleetchartImage: {type: :string},
              extendedHolo: {"$ref": "#/components/schemas/MediaFile"}
            }
          })
        end
      end
    end
  end
end
