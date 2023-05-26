# frozen_string_literal: true

module V1
  module Schemas
    class MediaImage
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          source: {type: :string, format: :uri},
          small: {type: :string, format: :uri},
          medium: {type: :string, format: :uri},
          large: {type: :string, format: :uri}
        },
        required: %w[source small medium large]
      })
    end
  end
end
