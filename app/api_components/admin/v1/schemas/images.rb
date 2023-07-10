# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Images < Shared::V1::Schemas::BaseList
        include SchemaConcern

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/Image"}}
          },
          additionalProperties: false,
          required: %w[items]
        })
      end
    end
  end
end
