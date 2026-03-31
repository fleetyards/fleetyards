# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetInviteUrl
        include Rswag::SchemaComponents::Component

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
            usageCount: {type: :integer},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[token url usageCount createdAt updatedAt]
        })
      end
    end
  end
end
