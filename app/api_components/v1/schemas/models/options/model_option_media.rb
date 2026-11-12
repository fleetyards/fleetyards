# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Options
        class ModelOptionMedia
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              storeImage: ::Shared::V1::Schemas::MediaFile,
              angledView: ::Shared::V1::Schemas::MediaFile,
              angledViewColored: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
