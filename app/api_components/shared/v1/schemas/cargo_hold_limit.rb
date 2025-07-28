# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class CargoHoldLimit
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            dimensions: {"$ref": "#/components/schemas/CargoHoldDimension"},
            capacity: {type: :integer}
          },
          additionalProperties: false,
          required: %w[dimensions capacity]
        })
      end
    end
  end
end
