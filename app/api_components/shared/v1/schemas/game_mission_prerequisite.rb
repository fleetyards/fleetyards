# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One thing a player has to have, or not have, before a mission is
      # offered. Most fields belong to one `kind`, which is why only it is
      # required.
      class GameMissionPrerequisite
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            kind: ::Shared::V1::Schemas::Enums::GameMissionPrerequisiteKindEnum,

            # Crime stat only: the band a player's CrimeStat has to sit in.
            min: {type: [:integer, :null]},
            max: {type: [:integer, :null]},

            # Reputation only. `excluded` means the player has to be outside
            # the band.
            orgName: {type: [:string, :null]},
            orgKey: {type: [:string, :null]},
            minStanding: {type: [:string, :null]},
            maxStanding: {type: [:string, :null]},
            excluded: {type: :boolean},

            # Completed or excluded missions: how many, and the missions that
            # count towards it.
            count: {type: [:integer, :null]},
            # Whether this mission is among them: excluded, it can be done once
            # only; required, it counts its own repeats.
            includesSelf: {type: :boolean},
            missions: {type: :array, items: ::Shared::V1::Schemas::GameMissionLink}
          },
          additionalProperties: false,
          required: %w[kind excluded includesSelf missions]
        })
      end
    end
  end
end
