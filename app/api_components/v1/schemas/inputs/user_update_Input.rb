# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class UserUpdateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            avatar: {type: :file},
            removeAvatar: {type: :boolean},
            rsiHandle: {type: :string},
            homepage: {type: :string},
            discord: {type: :string},
            youtube: {type: :string},
            guilded: {type: :string},
            twitch: {type: :string},
            saleNotify: {type: :boolean},
            publicHangar: {type: :boolean},
            publicHangarLoaners: {type: :boolean},
            publicWishlist: {type: :boolean},
            hideOwner: {type: :boolean}
          },
          additionalProperties: false
        })
      end
    end
  end
end
