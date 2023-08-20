# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Gallery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            type: {type: :string},
            name: {type: :string},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[id type name slug]
        })
      end
    end
  end
end
