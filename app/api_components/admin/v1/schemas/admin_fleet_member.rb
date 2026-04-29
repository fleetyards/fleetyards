# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminFleetMember
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            userId: {type: :string, format: :uuid},
            username: {type: :string},
            email: {type: :string},
            avatar: {"$ref": "#/components/schemas/MediaFile"},
            rsiHandle: {type: :string},
            role: {type: :string},
            status: {type: :string},
            acceptedAt: {type: :string, format: "date-time"},
            lastActiveAt: {type: :string, format: "date-time"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id userId username email status createdAt updatedAt]
        })
      end
    end
  end
end
