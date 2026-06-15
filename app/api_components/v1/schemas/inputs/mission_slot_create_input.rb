# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class MissionSlotCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slottableType: {type: :string, enum: %w[MissionTeam MissionShip]},
            slottableId: {type: :string, format: :uuid},
            title: {type: :string},
            description: {type: [:string, :null]}
          },
          required: %w[slottableType slottableId title],
          additionalProperties: false
        })
      end
    end
  end
end
