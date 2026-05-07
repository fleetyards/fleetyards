# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLoadoutInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, nullable: true},
            url: {type: :string},
            fromDefaults: {type: :boolean},
            vehicleLoadoutHardpointsAttributes: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  modelHardpointId: {type: :string, format: :uuid},
                  componentId: {type: :string, format: :uuid, nullable: true},
                  _destroy: {type: :boolean}
                }
              }
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
