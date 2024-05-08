# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Imports < ::Shared::V1::Schemas::BaseList
        include SchemaConcern

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/Import"}}
          },
          required: %w[items]
        })
      end
    end
  end
end
