# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class Hangar < Shared::V1::Schemas::BaseList
        include SchemaConcern

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/Vehicle"}}
          },
          additionalProperties: false,
          required: %w[items]
        })
      end
    end
  end
end
