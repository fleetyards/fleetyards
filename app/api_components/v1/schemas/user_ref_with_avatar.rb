# frozen_string_literal: true

module V1
  module Schemas
    # UserRef plus the avatar, for the payloads that have to show who someone
    # is rather than only name them. Kept separate rather than widening UserRef,
    # which every other embedded user in the API points at.
    class UserRefWithAvatar
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          username: {type: :string},
          avatar: ::Shared::V1::Schemas::MediaFile
        }
      })
    end
  end
end
