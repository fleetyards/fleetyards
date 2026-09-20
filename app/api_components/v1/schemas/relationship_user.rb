# frozen_string_literal: true

module V1
  module Schemas
    # The other person in a friendship. Not `UserRef`: a friends list draws
    # avatars, and `UserRef` is two fields with no `additionalProperties: false`
    # -- adding the avatar there would document it for every caller of every
    # endpoint that already uses it.
    class RelationshipUser
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          username: {type: :string},
          avatar: ::Shared::V1::Schemas::MediaFile,
          # Both only once the friendship is accepted, so neither is required:
          # the same shape carries a request nobody has answered yet.
          lastActiveAt: {type: [:string, :null], format: "date-time"},
          online: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[id username]
      })
    end
  end
end
