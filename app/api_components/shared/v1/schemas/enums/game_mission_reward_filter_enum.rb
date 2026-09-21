# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Everything a mission can be said to pay, which is what a reader
        # filters by and what `rewardKinds` lists.
        #
        # One more than `GameMissionRewardKindEnum`, which is what a single
        # reward row can be: a recipe is handed out through a reward pool rather
        # than as a contract result, so there is no reward row for it -- but it
        # is very much something the mission gives you, and nobody filtering
        # "what do I get" should have to know which side of the export it came
        # from.
        class GameMissionRewardFilterEnum
          include OpenapiRuby::Components::Base

          VALUES = ::GameMissionBuild::REWARD_KINDS

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
