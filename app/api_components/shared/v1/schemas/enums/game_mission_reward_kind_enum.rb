# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # What a mission can pay, as the export states it.
        #
        # `calculated` is deliberately absent. It is what 2352 of the 2536
        # contracts award and it states nothing at all -- the game computes the
        # figure at run time -- so a page could only say that there is one.
        class GameMissionRewardKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::GameMissionReward::KINDS

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
