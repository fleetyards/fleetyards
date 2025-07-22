# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Components < ::Shared::V1::Schemas::BaseList
        include SchemaConcern

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/Component"}}
          },
          required: %w[items]
        })
      end
    end
  end
end
