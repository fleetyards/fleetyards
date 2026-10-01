# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A place, named, for a link to its page.
      class LocationLink
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: [:string, :null]},
            slug: {type: :string},
            kind: ::Shared::V1::Schemas::Enums::LocationKindEnum
          },
          additionalProperties: false,
          required: %w[id slug kind]
        })
      end
    end
  end
end
