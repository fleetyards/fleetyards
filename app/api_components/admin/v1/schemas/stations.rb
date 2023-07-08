# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Stations
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/StationMinimal"}},
            meta: {"$ref": "#/components/schemas/Meta"}
          },
          required: %w[items meta]
        })
      end
    end
  end
end
