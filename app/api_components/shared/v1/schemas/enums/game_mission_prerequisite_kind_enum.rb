# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class GameMissionPrerequisiteKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::GameMissionPrerequisite::KINDS

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
