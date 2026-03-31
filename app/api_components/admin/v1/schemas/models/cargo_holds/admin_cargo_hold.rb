# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module CargoHolds
          class AdminCargoHold
            include Rswag::SchemaComponents::Component

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                modelId: {type: :string, format: :uuid},
                name: {type: :string, nullable: true},
                position: {type: :integer, nullable: true},
                capacityScu: {type: :number},
                dimensionX: {type: :number},
                dimensionY: {type: :number},
                dimensionZ: {type: :number},
                offsetX: {type: :number, nullable: true},
                offsetY: {type: :number, nullable: true},
                offsetZ: {type: :number, nullable: true},
                rotation: {type: :integer, nullable: true},
                model: {
                  type: :object,
                  properties: {
                    id: {type: :string, format: :uuid},
                    name: {type: :string},
                    slug: {type: :string}
                  },
                  required: %w[id name slug]
                },
                createdAt: {type: :string, format: "date-time"},
                updatedAt: {type: :string, format: "date-time"}
              },
              additionalProperties: false,
              required: %w[id modelId capacityScu dimensionX dimensionY dimensionZ createdAt updatedAt]
            })
          end
        end
      end
    end
  end
end
