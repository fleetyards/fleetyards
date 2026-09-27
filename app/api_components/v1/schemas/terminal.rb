# frozen_string_literal: true

module V1
  module Schemas
    # A UEX commodity terminal. The location fields are names rather than
    # references: nothing else in the catalogue models systems or stations.
    class Terminal
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          nickname: {type: [:string, :null]},
          displayName: {type: [:string, :null]},
          code: {type: [:string, :null]},
          starSystem: {type: [:string, :null]},
          planet: {type: [:string, :null]},
          orbit: {type: [:string, :null]},
          moon: {type: [:string, :null]},
          spaceStation: {type: [:string, :null]},
          city: {type: [:string, :null]},
          outpost: {type: [:string, :null]},

          # The largest crate it handles, in SCU. Null where nobody has
          # measured it yet, which is not the same as "no crates".
          maxContainerSize: {type: [:integer, :null]},
          hasFreightElevator: {type: :boolean},
          hasLoadingDock: {type: :boolean},
          hasDockingPort: {type: :boolean},
          available: {type: :boolean},
          contactUrl: {type: [:string, :null], format: :uri}
        },
        additionalProperties: false,
        required: %w[id name hasFreightElevator hasLoadingDock hasDockingPort available]
      })
    end
  end
end
