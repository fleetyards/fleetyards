# frozen_string_literal: true

module Admin
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
          required: %w[code message]
        })
      end
    end
  end
end
