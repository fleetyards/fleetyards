# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleCheckSerialInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            serial: {type: :string}
          },
          additionalProperties: false,
          required: %w[serial]
        })
      end
    end
  end
end
