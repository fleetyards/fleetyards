# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class CargoHoldDimension
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            x: {type: :number},
            y: {type: :number},
            z: {type: :number}
          },
          additionalProperties: false,
          required: %w[x y z]
        })
      end
    end
  end
end
