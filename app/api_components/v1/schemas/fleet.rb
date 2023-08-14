# frozen_string_literal: true

module V1
  module Schemas
    class Fleet < FleetMinimal
      include SchemaConcern

      schema({
        properties: {
          myRole: {"$ref": "#/components/schemas/FleetMembershipRoleEnum"},
          primary: {type: :boolean}
        }
      })
    end
  end
end
