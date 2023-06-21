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
          longName: {type: :string}
        },
        required: %w[name slug]
      })
    end
  end
end
