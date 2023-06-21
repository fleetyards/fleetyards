# frozen_string_literal: true

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
        required: %w[name slug]
      })
    end
  end
end
