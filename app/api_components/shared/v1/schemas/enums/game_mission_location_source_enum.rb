# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # How a mission is known to take place at a place: through a location
        # template one of its slots can pick, or because its text names it.
        class GameMissionLocationSourceEnum
          include OpenapiRuby::Components::Base

          VALUES = ::GameMissionLocation::SOURCES

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
