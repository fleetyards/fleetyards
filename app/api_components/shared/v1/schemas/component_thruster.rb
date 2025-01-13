# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentThruster
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            thrustCapacity: {type: :number},
            thrusterType: {type: :string},
            thrusterClass: {"$ref": "#/components/schemas/ThrusterClassEnum"},
            fuelBurnRatePer10KNewton: {type: :number}
          },
          additionalProperties: false,
          required: %w[capacity thrusterType fuelBurnRatePer10KNewton]
        })
      end
    end
  end
end
