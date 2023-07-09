# frozen_string_literal: true

module V1
  module Schemas
    class Starsystems < Shared::V1::Schemas::BaseList
      include SchemaConcern

      schema({
        properties: {
          items: {type: :array, items: {"$ref": "#/components/schemas/StarsystemMinimal"}}
        },
        required: %w[items]
      })
    end
  end
end
