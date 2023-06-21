# frozen_string_literal: true

module V1
  module Schemas
    class ValidationError
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          code: {type: :string},
          errors: {
            type: :array,
            items: {"$ref" => "#/components/schemas/FieldError"}
          },
          message: {type: :string}
        },
        required: %w[code message]
      })
    end
  end
end
