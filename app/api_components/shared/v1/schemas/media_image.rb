# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class MediaImage
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            large: {type: :string, format: :uri},
            medium: {type: :string, format: :uri},
            small: {type: :string, format: :uri},
            source: {type: :string, format: :uri}
          },
          additionalProperties: false,
          required: %w[source small medium large]
        })
      end
    end
  end
end
