# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetMembershipStatusEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::FleetMembership.aasm.states.map(&:name)
        })
      end
    end
  end
end
