# frozen_string_literal: true

module V1
  module Schemas
    class VehicleCheckSerialResponse
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          serialTaken: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[serialTaken]
      })
    end
  end
end
