# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Dock
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string, nullable: true},
            dockType: {type: :string},
            dockTypeLabel: {type: :string},
            shipSize: {type: :string},
            shipSizeLabel: {type: :string},
            group: {type: :string, nullable: true},
            length: {type: :number, nullable: true},
            beam: {type: :number, nullable: true},
            height: {type: :number, nullable: true},
            minShipSize: {type: :integer, nullable: true},
            maxShipSize: {type: :integer, nullable: true},
            modelId: {type: :string, format: :uuid, nullable: true},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id dockType dockTypeLabel shipSize shipSizeLabel createdAt updatedAt]
        })
      end
    end
  end
end
