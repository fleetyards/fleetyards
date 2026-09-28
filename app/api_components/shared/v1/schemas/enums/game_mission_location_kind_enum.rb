# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Where a contract takes place. The game picks the location at run
        # time from a tag search, so this is the kind of every place the search
        # can match: all on a planet or moon, all in space, or either.
        class GameMissionLocationKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::GameMission::LOCATION_KINDS

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
