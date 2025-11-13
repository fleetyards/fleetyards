# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BaseList
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            meta: {"$ref": "#/components/schemas/Meta"}
          },
          additionalProperties: false,
          required: %w[items meta]
        })
      end
    end
  end
end
