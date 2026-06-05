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
            name: {type: :string},
            dockType: {type: :string},
            dockTypeLabel: {type: :string},
            shipSize: {type: :string},
            shipSizeLabel: {type: :string},
            group: {type: :string},
            length: {type: :number},
            beam: {type: :number},
            height: {type: :number},
            minShipSize: {type: :integer},
            maxShipSize: {type: :integer},
            modelId: {type: :string, format: :uuid},
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
