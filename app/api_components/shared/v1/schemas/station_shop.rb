# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class StationShop
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
end
