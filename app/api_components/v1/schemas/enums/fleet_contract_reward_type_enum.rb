# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetContractRewardTypeEnum
        include OpenapiRuby::Components::Base

        VALUES = ::FleetContract::REWARD_TYPES.keys.map(&:to_s).freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
