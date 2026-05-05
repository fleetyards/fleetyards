# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventShipCreateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            title: {type: :string, nullable: true},
            description: {type: :string, nullable: true},
            modelId: {type: :string, format: :uuid, nullable: true},
            classification: {type: :string, nullable: true},
            focus: {type: :string, nullable: true},
            minSize: {type: :string, nullable: true},
            maxSize: {type: :string, nullable: true},
            minCrew: {type: :integer, nullable: true},
            minCargo: {type: :number, nullable: true},
            positionIds: {
              type: :array,
              items: {type: :string, format: :uuid}
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
