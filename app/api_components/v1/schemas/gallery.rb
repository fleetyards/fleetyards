# frozen_string_literal: true

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
        required: %w[id name slug]
      })
    end
  end
end
