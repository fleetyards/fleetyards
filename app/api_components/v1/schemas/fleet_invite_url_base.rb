# frozen_string_literal: true

module V1
  module Schemas
    class FleetInviteUrlBase
      include SchemaConcern

      schema_hidden true

      schema({
        type: :object,
        properties: {
          token: {type: :string},
          url: {type: :string, format: :uri},
          expiresAfter: {type: :string, format: "date-time"},
          expiresAfterLabel: {type: :string},
          expired: {type: :boolean},
          limit: {type: :integer},
          limitReached: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[token url]
      })
    end
  end
end
