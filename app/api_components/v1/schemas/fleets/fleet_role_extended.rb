# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetRoleExtended
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            rank: {type: :string},
            permanent: {type: :boolean},
            resourceAccess: {type: :array, items: {type: :string}},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name slug rank permanent resourceAccess createdAt updatedAt]
        })
      end
    end
  end
end
