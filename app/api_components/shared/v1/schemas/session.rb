# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Session
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            pagination: {"$ref": "#/components/schemas/Pagination"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
