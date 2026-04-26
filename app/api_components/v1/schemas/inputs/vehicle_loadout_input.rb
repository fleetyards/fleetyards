# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLoadoutInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            url: {type: :string, description: "Auto-detected as erkul or spviewer URL"},
            erkulUrl: {type: :string, nullable: true},
            spviewerUrl: {type: :string, nullable: true},
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
