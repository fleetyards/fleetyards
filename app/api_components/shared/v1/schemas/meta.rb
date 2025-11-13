# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Meta
        include Rswag::SchemaComponents::Component

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
