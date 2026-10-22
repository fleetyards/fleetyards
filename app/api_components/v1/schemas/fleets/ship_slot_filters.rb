# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # What a ship slot will accept, shared by mission and event ships.
      class ShipSlotFilters
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            classification: {type: :string},
            foci: {type: :array, items: ::Shared::V1::Schemas::Enums::ModelFocusEnum},
            fociLabels: {type: :array, items: {type: :string}},
            minSize: {type: :string},
            maxSize: {type: :string},
            minCrew: {type: :integer},
            minCargo: {type: :number}
          }
        })
      end
    end
  end
end
