# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Meta
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            pagination: {"$ref": "#/components/schemas/Pagination"}
          }
        })
      end
    end
  end
end
