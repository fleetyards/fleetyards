# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # How hard the game's own designers rated it, on four axes.
      #
      # Each is a 1-7 the export writes on the end of a sentence
      # ("Hard_PvE_or_Easy_PvP_action_5"). The sentence is developer-facing and
      # is not carried; the number is, and the labels for it are ours.
      class GameMissionDifficulty
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # Which weighting the game combines the four axes with. Named
            # rather than applied: the weights are a record of their own, and a
            # single score is a decision this payload does not make.
            profile: {type: [:string, :null]},

            mechanicalSkill: {type: [:integer, :null]},
            mentalLoad: {type: [:integer, :null]},
            riskOfLoss: {type: [:integer, :null]},
            gameKnowledge: {type: [:integer, :null]}
          },
          additionalProperties: false,
          required: %w[]
        })
      end
    end
  end
end
