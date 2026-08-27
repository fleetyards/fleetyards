# frozen_string_literal: true

module V1
  module Schemas
    class Manufacturer
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          code: {type: :string},
          logo: ::Shared::V1::Schemas::MediaFile,
          icon: ::Shared::V1::Schemas::MediaFile,
          longName: {type: :string},
          scRef: {type: :string},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[name slug createdAt updatedAt]
      })
    end
  end
end
