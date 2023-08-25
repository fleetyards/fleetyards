# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ViewImage
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            source: {type: :string, format: :uri},
            small: {type: :string, format: :uri},
            medium: {type: :string, format: :uri},
            large: {type: :string, format: :uri},
            xlarge: {type: :string, format: :uri},
            width: {type: :integer},
            height: {type: :integer}
          },
          additionalProperties: false,
          required: %w[source small medium large xlarge width height]
        })
      end
    end
  end
end
