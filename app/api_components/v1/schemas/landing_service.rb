# frozen_string_literal: true

module V1
  module Schemas
    class LandingService
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          key: ::Shared::V1::Schemas::Enums::LandingServiceEnum,
          icon: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false,
        required: %w[key]
      })
    end
  end
end
