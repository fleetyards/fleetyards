# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetMembershipShipsFilterEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::FleetMembership.ships_filters.keys
        })
      end
    end
  end
end
