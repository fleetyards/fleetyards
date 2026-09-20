# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        # Which ladder the entry's class is measured on. The two do not line up:
        # ship classes are the game's six pad sizes, vehicle classes the curated
        # ATLS-to-Nova ladder.
        class DockCapacityLadderEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::DockCapacity.ladders.keys,
            "x-enumNames": ::DockCapacity.ladders.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
