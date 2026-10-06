# frozen_string_literal: true

module V1
  module Schemas
    # What a pilot can land in or dock at, from the game's object containers.
    class LocationFacilities
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          hangars: {type: :array, items: ::V1::Schemas::LocationHangar},
          landingPads: {type: :array, items: ::V1::Schemas::LocationPad},
          # Pads only a ground vehicle fits on.
          vehiclePads: {type: :array, items: ::V1::Schemas::LocationPad},
          dockingTubes: {type: :integer}
        },
        additionalProperties: false,
        required: %w[hangars landingPads vehiclePads dockingTubes]
      })
    end
  end
end
