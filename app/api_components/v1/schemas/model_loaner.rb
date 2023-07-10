# frozen_string_literal: true

module V1
  module Schemas
    class ModelLoaner
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string}
        },
        additionalProperties: false,
        required: %w[name slug]
      })
    end
  end
end
