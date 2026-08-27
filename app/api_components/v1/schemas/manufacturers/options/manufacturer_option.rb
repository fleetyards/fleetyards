# frozen_string_literal: true

module V1
  module Schemas
    module Manufacturers
      module Options
        class ManufacturerOption
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              logo: ::Shared::V1::Schemas::MediaFile,
              icon: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false,
            required: %w[id name slug logo]
          })
        end
      end
    end
  end
end
