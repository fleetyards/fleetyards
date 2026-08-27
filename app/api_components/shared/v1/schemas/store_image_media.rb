# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class StoreImageMedia
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            storeImage: ::Shared::V1::Schemas::MediaFile
          },
          additionalProperties: false
        })
      end
    end
  end
end
