# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # How a place is linked to a mission: through a location template one
        # of its slots can pick, because its text names it, or because the
        # mission is offered there. Extensible, since each new way of linking
        # one adds a value.
        class GameMissionLocationSourceEnum
          include OpenapiRuby::Components::Base

          VALUES = ::GameMissionLocation::SOURCES

          schema({
            type: :string,
            enum: VALUES,
            "x-extensible-enum": VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
