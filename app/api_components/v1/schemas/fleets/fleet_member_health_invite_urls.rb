# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMemberHealthInviteUrls
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            totalCount: {type: :integer},
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  token: {type: :string},
                  url: {type: :string},
                  createdBy: {type: [:string, :null]},
                  createdAt: {type: :string, format: "date-time"},
                  expiresAfter: {type: [:string, :null], format: "date-time"},
                  limit: {type: [:integer, :null], description: "Uses left; null for no limit"},
                  usageCount: {type: :integer}
                },
                required: %w[token url createdAt usageCount],
                additionalProperties: false
              }
            }
          },
          required: %w[totalCount items],
          additionalProperties: false
        })
      end
    end
  end
end
