# frozen_string_literal: true

module V1
  module Schemas
    module Sorts
      class FleetSquadronMemberSortEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: FleetMembership::SQUADRON_ROSTER_SORTING_PARAMS,
          "x-enumNames": FleetMembership::SQUADRON_ROSTER_SORTING_PARAMS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
