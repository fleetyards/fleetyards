# frozen_string_literal: true

module V1
  module Schemas
    class CargoOption
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: "string"},
          value: {type: "string"},
          cargo: {type: :number}
        },
        additionalProperties: false,
        required: %w[name value cargo]
      })
    end
  end
end
