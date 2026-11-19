# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # What the game's starmap lists a place as offering.
        class LocationAmenityEnum
          include OpenapiRuby::Components::Base

          VALUES = ::Location::AMENITIES

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
