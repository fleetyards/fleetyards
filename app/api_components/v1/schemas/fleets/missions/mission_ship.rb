# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Missions
        class MissionShip
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              missionTeamId: {type: :string, format: :uuid},
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
              filters: ::V1::Schemas::Fleets::ShipSlotFilters,
              slots: {
                type: :array,
                items: ::V1::Schemas::Fleets::Missions::MissionSlot
              }
            },
            required: %w[id missionTeamId position strict allowedModels slots],
            additionalProperties: false
          })
        end
      end
    end
  end
end
