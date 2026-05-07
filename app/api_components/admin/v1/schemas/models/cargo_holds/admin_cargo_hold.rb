# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module CargoHolds
          class AdminCargoHold
            include OpenapiRuby::Components::Base

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                parentType: {type: :string},
                parentId: {type: :string, format: :uuid},
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
                parent: {
                  type: :object,
                  properties: {
                    id: {type: :string, format: :uuid},
                    name: {type: :string},
                    slug: {type: :string, nullable: true}
                  },
                  required: %w[id name]
                },
                createdAt: {type: :string, format: "date-time"},
                updatedAt: {type: :string, format: "date-time"}
              },
              additionalProperties: false,
              required: %w[id parentType parentId capacityScu dimensionX dimensionY dimensionZ createdAt updatedAt]
            })
          end
        end
      end
    end
  end
end
