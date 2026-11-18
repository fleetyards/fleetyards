# frozen_string_literal: true

module V1
  module Schemas
    # A UEX trade terminal at a place.
    class LocationTerminal
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          # What a hauler can load there, as UEX lists it.
          hasFreightElevator: {type: :boolean},
          hasLoadingDock: {type: :boolean},
          hasDockingPort: {type: :boolean},
          # The largest container it takes, in SCU.
          maxContainerSize: {type: [:integer, :null]}
        },
        additionalProperties: false,
        required: %w[id name hasFreightElevator hasLoadingDock hasDockingPort maxContainerSize]
      })
    end
  end
end
