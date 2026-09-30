# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # What an inline `[*…*]` token can name. Sourced from the resolver, so the
      # schema cannot drift from what the lookup answers.
      class CatalogueTokenTypeEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Catalogue::TokenResolver::CATALOGUES.values.map(&:name).freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
