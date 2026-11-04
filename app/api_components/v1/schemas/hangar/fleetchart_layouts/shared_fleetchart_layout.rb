# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module FleetchartLayouts
        class SharedFleetchartLayout
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              colored: {type: :boolean},
              background: ::V1::Schemas::Enums::FleetchartBackgroundEnum,
              username: {type: [:string, :null]},
              publicHangar: {type: :boolean},
              placements: {type: :array, items: FleetchartPlacement},
              vehicles: {type: :array, items: ::V1::Schemas::Vehicles::VehiclePublic},
              cataloguePlacements: {type: :array, items: FleetchartCataloguePlacement},
              models: {type: :array, items: ::V1::Schemas::Models::Model}
            },
            required: %w[name colored background username publicHangar placements vehicles cataloguePlacements models]
          })
        end
      end
    end
  end
end
