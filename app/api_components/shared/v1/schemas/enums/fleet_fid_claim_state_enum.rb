# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class FleetFidClaimStateEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::FleetFidClaim.states.keys,
            "x-enumNames": ::FleetFidClaim.states.keys.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
