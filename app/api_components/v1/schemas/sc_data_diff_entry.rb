# frozen_string_literal: true

module V1
  module Schemas
    # `slug` is absent when the build the reader is on does not have the record.
    # `context` tells apart entries of the same name: a component's ships, a
    # mission's giver.
    class ScDataDiffEntry
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          kind: ::V1::Schemas::Enums::ScDataDiffKindEnum,
          name: {type: :string},
          slug: {type: [:string, :null]},
          context: {type: [:string, :null]},
          fields: {type: :array, items: ::V1::Schemas::ScDataDiffField}
        },
        additionalProperties: false,
        required: %w[id kind name fields]
      })
    end
  end
end
