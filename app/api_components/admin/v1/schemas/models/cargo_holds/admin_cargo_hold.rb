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
                name: {type: [:string, :null]},
                position: {type: [:integer, :null]},
                capacityScu: {type: :number},
                dimensionX: {type: :number},
                dimensionY: {type: :number},
                dimensionZ: {type: :number},
                offsetX: {type: [:number, :null]},
                offsetY: {type: [:number, :null]},
                offsetZ: {type: [:number, :null]},
                rotation: {type: [:integer, :null]},
                parent: {
                  type: :object,
                  properties: {
                    id: {type: :string, format: :uuid},
                    name: {type: :string},
                    slug: {type: [:string, :null]}
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
