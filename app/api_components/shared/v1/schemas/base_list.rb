# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BaseList
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            meta: {"$ref": "#/components/schemas/Meta"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
