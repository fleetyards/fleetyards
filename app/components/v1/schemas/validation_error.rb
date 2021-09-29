# frozen_string_literal: true

module V1
  module Schemas
    class ValidationError < ::BaseSchema
      data_type :object

      property :code, {type: :string}
      property :message, {type: :string}
      property :errors, {
        type: :array,
        items: {"$ref" => "#/components/schemas/FieldError"}
      }

      required %w[code message]
    end
  end
end
