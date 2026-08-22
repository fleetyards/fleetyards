# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class MissionSlotSortInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slottableType: {type: :string, enum: %w[MissionTeam MissionShip]},
            slottableId: {type: :string, format: :uuid},
            sorting: {
              type: :array,
              items: {type: :string, format: :uuid}
            }
          },
          required: %w[slottableType slottableId sorting],
          additionalProperties: false
        })
      end
    end
  end
end
