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
              username: {type: :string},
              placements: {type: :array, items: FleetchartPlacement},
              vehicles: {type: :array, items: ::V1::Schemas::Vehicles::VehiclePublic}
            },
            required: %w[name colored username placements vehicles]
          })
        end
      end
    end
  end
end
