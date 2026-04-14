# frozen_string_literal: true

module V1
  module Schemas
    class Notifications < ::Shared::V1::Schemas::BaseList
      include Rswag::SchemaComponents::Component

      schema({
        properties: {
          items: {type: :array, items: {"$ref": "#/components/schemas/Notification"}}
        },
        required: %w[items]
      })
    end
  end
end
