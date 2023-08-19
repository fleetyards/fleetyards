# frozen_string_literal: true

module V1
  module Schemas
    class Manufacturer
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          code: {type: :string, nullable: true},
          logo: {type: :string, nullable: true},
          longName: {type: :string},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[name slug createdAt updatedAt]
      })
    end
  end
end
