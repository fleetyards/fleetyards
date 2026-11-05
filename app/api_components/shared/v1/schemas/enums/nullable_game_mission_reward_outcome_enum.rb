# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # See NullableInventoryItemTypeEnum for why nullable enums are their own
        # component instead of anyOf: [$ref, {type: :null}].
        class NullableGameMissionRewardOutcomeEnum
          include OpenapiRuby::Components::Base

          VALUES = (::GameMissionReward::OUTCOMES + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": ::GameMissionReward::OUTCOMES.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
