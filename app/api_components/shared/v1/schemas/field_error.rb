# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class FieldError
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            attribute: {type: :string},
            messages: {
              type: :array,
              items: {"$ref" => "#/components/schemas/StandardError"}
            }
          },
          additionalProperties: false,
          required: %w[attribute messages]
        })
      end
    end
  end
end
