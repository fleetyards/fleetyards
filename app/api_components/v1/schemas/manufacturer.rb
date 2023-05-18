# frozen_string_literal: true

module V1
  module Schemas
    class Manufacturer
      include SchemaConcern

      schema :base, {
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          code: {type: :string},
          logo: {type: :string, nullable: true},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[name slug createdAt updatedAt]
      }
    end
  end
end
