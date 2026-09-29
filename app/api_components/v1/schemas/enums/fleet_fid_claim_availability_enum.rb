# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetFidClaimAvailabilityEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::FleetFidClaim::AVAILABILITIES,
          "x-enumNames": ::FleetFidClaim::AVAILABILITIES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
