# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class FleetMembershipShipsFilterEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::FleetMembership.ships_filters.keys,
            "x-enumNames": ::FleetMembership.ships_filters.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
