# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BaseList
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            items: {
              type: :array,
              items: {type: :object}
            },
            meta: {"$ref": "#/components/schemas/Meta"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
