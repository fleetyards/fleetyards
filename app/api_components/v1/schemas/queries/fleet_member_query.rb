# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetMemberQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            usernameCont: {type: :string},
            nameCont: {type: :string, deprecated: true, description: "Use usernameCont instead"},
            roleIn: {type: :array, items: {"$ref": "#/components/schemas/FleetMembershipRoleEnum"}},
            sorts: {oneOf: [{
              type: :array, items: {type: :string}
            }, {
              type: :string
            }]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
