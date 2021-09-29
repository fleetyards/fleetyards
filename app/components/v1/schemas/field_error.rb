# frozen_string_literal: true

module V1
  module Schemas
    class FieldError < ::BaseSchema
      data_type :object

      property :attribute, {type: :string}
      property :messages, {
        type: :array,
        items: {"$ref" => "#/components/schemas/StandardError"}
      }

      required %w[attribute messages]
    end
  end
end
