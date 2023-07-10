# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Gallery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[id name slug]
        })
      end
    end
  end
end
