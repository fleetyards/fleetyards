# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadout
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            active: {type: :boolean},
            url: {type: :string},
            urlSource: {type: :string},
            hardpoints: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  modelHardpointId: {type: :string, format: :uuid},
                  hardpoint: {"$ref": "#/components/schemas/ModelHardpoint"},
                  component: {"$ref": "#/components/schemas/Component"}
                }
              }
            },
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id active url hardpoints createdAt updatedAt]
        })
      end
    end
  end
end
