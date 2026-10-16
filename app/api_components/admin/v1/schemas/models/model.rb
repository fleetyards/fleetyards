# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        class Model < ::V1::Schemas::Models::Model
          include OpenapiRuby::Components::Base

          schema({
            properties: {
              hidden: {type: :boolean},
              keepCargo: {type: :boolean, description: "The cargo entered stands instead of the game-file holds"},
              active: {type: :boolean},
              scKey: {type: :string},
              positionsNeedCuration: {type: :boolean},
              scLength: {type: :number},
              scBeam: {type: :number},
              scHeight: {type: :number},
              dimensionsMeasuredAt: {type: :string, format: :"date-time"},
              # Read from the game files but not shown publicly: lockers cannot be
              # used in game yet.
              lockers: {type: :integer},
              media: AdminModelMedia
            },
            required: %w[hidden keepCargo active media]
          })
        end
      end
    end
  end
end
