# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetMembershipRoleEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::FleetMembership.roles.keys
        })
      end
    end
  end
end
