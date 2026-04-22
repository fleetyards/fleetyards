# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class FleetMembershipStatusEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::FleetMembership.aasm.states.map(&:name),
            "x-enumNames": ::FleetMembership.aasm.states.map { |s| transform_enum_key(s.name) }
          })
        end
      end
    end
  end
end
