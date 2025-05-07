# frozen_string_literal: true

module V1
  module Schemas
    class UserPublic
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          username: {type: :string},
          avatar: {type: :string},
          rsiHandle: {type: :string},
          discord: {type: :string},
          youtube: {type: :string},
          twitch: {type: :string},
          guilded: {type: :string},
          homepage: {type: :string},
          publicHangarLoaners: {type: :boolean},
          publicWishlist: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[username publicHangarLoaners publicWishlist]
      })
    end
  end
end
