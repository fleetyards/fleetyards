# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # What a place is. Read off the game's map icon before its type: Levski
        # is a `Manmade` record the map draws as a landing zone, so a city.
        class LocationKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::Location::KINDS

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
