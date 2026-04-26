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
            erkulUrl: {type: :string, nullable: true},
            spviewerUrl: {type: :string, nullable: true},
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
          required: %w[id name active hardpoints createdAt updatedAt]
        })
      end
    end
  end
end
