# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetInviteUrl
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            token: {type: :string},
            url: {type: :string, format: :uri},
            expiresAfter: {type: :string, format: "date-time"},
            expiresAfterLabel: {type: :string},
            expired: {type: :boolean},
            limit: {type: :integer},
            limitReached: {type: :boolean},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[token url createdAt updatedAt]
        })
      end
    end
  end
end
