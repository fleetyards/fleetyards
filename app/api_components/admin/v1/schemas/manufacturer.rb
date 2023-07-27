# frozen_string_literal: true

module Admin
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
          additionalProperties: false,
          required: %w[name slug]
        })
      end
    end
  end
end
