# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Missions
        class MissionSlot
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              slottableType: {type: :string, enum: %w[MissionTeam MissionShip]},
              slottableId: {type: :string, format: :uuid},
              title: {type: :string},
              description: {type: :string},
              position: {type: :integer},
              derived: {type: :boolean},
              positionType: {type: :string}
            },
            required: %w[id slottableType slottableId title position derived],
            additionalProperties: false
          })
        end
      end
    end
  end
end
