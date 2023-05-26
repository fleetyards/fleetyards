# frozen_string_literal: true

module V1
  module Schemas
    class Paint
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string, nullable: true},
          slug: {type: :string, nullable: true}
        },
        required: %w[name slug]
      })

      schema :minimal,
        {
          properties: {
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[createdAt updatedAt]
        },
        extends: :base
    end
  end
end
