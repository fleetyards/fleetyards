# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventShip
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventTeamId: {type: :string, format: :uuid},
              title: {type: :string},
              displayTitle: {type: :string},
              description: {type: :string},
              position: {type: :integer},
              strict: {type: :boolean},
              model: ::V1::Schemas::Fleets::ShipModel,
              # The models a spot will take when it names several rather than
              # one; empty for the other two kinds of spot.
              allowedModels: {
                type: :array,
                items: ::V1::Schemas::Fleets::ShipModel
              },
              filters: ShipSlotFilters,
              slots: {
                type: :array,
                items: ::V1::Schemas::Fleets::Events::FleetEventSlot
              }
            },
            required: %w[id fleetEventTeamId position strict allowedModels slots],
            additionalProperties: false
          })
        end
      end
    end
  end
end
