# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module FleetchartLayouts
        class FleetchartLayout
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              colored: {type: :boolean},
              shareToken: {type: [:string, :null]},
              placements: {type: :array, items: FleetchartPlacement},
              cataloguePlacements: {type: :array, items: FleetchartCataloguePlacement},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            required: %w[id name colored placements cataloguePlacements createdAt updatedAt]
          })
        end
      end
    end
  end
end
