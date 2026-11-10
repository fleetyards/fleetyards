# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Fleetchart
        # One ship, pointing at its model and module package in the same
        # response rather than carrying them.
        class FleetFleetchartShip
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              modelId: {type: :string, format: :uuid},
              modulePackageId: {type: :string, format: :uuid},
              username: {type: :string},
              userDisplayName: {type: :string},
              squadron: FleetVehicleSquadron
            },
            required: %w[id modelId]
          })
        end
      end
    end
  end
end
