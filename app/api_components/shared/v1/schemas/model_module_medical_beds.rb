# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The medical beds the rooms of a module hold.
      class ModelModuleMedicalBeds
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            tiers: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  # 1 the best: the game's Hospital, then Clinic, then Ambulance.
                  tier: {type: [:integer, :null]},
                  name: {type: :string},
                  beds: {type: :integer}
                },
                additionalProperties: false,
                required: %w[tier name beds]
              }
            },
            # How many of them a player can respawn at.
            respawnBeds: {type: :integer}
          },
          additionalProperties: false,
          required: %w[tiers respawnBeds]
        })
      end
    end
  end
end
