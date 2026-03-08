# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Sorts
        class FleetMembershipSortEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: FleetMembership::ALLOWED_SORTING_PARAMS,
            "x-enumNames": FleetMembership::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
