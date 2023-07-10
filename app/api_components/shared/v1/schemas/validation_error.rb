# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ValidationError
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            code: {type: :string},
            message: {type: :string},
            errors: {
              type: :array,
              items: {"$ref" => "#/components/schemas/FieldError"}
            }
          },
          additionalProperties: false,
          required: %w[code message]
        })
      end
    end
  end
end
