# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class UserQuery
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              searchCont: {type: :string},
              usernameCont: {type: :string},
              usernameEq: {type: :string},
              emailCont: {type: :string},
              rsiHandleCont: {type: :string},
              idIn: {type: :array, items: {type: :string, format: :uuid}},
              usernameIn: {type: :array, items: {type: :string}},
              emailIn: {type: :array, items: {type: :string}},
              rsihandleIn: {type: :array, items: {type: :string}},
              sorts: {oneOf: [{
                type: :array, items: {"$ref": "#/components/schemas/UserSortEnum"}
              }, {
                "$ref": "#/components/schemas/UserSortEnum"
              }]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
