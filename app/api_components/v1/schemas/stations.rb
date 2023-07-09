# frozen_string_literal: true

module V1
  module Schemas
    class Stations < Shared::V1::Schemas::BaseList
      include SchemaConcern

      schema({
        properties: {
          items: {type: :array, items: {"$ref": "#/components/schemas/StationMinimal"}}
        },
        required: %w[items]
      })
    end
  end
end
