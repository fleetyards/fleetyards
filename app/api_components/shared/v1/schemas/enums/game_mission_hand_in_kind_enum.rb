# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class GameMissionHandInKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::GameMissionHandIn::KINDS

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
