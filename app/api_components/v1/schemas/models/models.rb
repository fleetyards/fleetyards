# frozen_string_literal: true

module V1
  module Schemas
    module Models
      class Models < Shared::V1::Schemas::BaseList
        include SchemaConcern

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/Model"}}
          },
          required: %w[items]
        })
      end
    end
  end
end
