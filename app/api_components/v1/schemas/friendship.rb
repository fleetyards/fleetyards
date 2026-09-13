# frozen_string_literal: true

module V1
  module Schemas
    # A friendship or a request, from one side. `user` is always the *other*
    # party -- a friendship has no owner, and the row is addressed by whoever
    # is not you.
    class Friendship
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          state: ::V1::Schemas::Enums::RelationshipStateEnum,
          direction: ::V1::Schemas::Enums::RelationshipDirectionEnum,
          user: ::V1::Schemas::RelationshipUser,
          acceptedAt: {type: [:string, :null], format: "date-time"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id state direction user createdAt updatedAt]
      })
    end
  end
end
