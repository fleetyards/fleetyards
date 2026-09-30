# frozen_string_literal: true

module V1
  module Schemas
    class PushSubscription
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          browser: {type: [:string, :null]},
          os: {type: [:string, :null]},
          lastDeliveredAt: {type: [:string, :null], format: "date-time"},
          createdAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id browser os lastDeliveredAt createdAt]
      })
    end
  end
end
