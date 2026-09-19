# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetMembershipBlueprintsFilterEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::FleetMembership.blueprints_filters.keys,
          "x-enumNames": ::FleetMembership.blueprints_filters.keys.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
