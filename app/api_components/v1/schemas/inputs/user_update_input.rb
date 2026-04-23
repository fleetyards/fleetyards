# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class UserUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            avatar: {type: :string, nullable: true},
            removeAvatar: {type: :boolean},
            rsiHandle: {type: :string, nullable: true},
            homepage: {type: :string, nullable: true},
            discord: {type: :string, nullable: true},
            youtube: {type: :string, nullable: true},
            guilded: {type: :string, nullable: true},
            twitch: {type: :string, nullable: true},
            saleNotify: {type: :boolean},
            publicHangar: {type: :boolean},
            publicHangarLoaners: {type: :boolean},
            publicHangarStats: {type: :boolean},
            publicWishlist: {type: :boolean},
            hideOwner: {type: :boolean},
            location: {type: :string, nullable: true},
            currentSystem: {type: :string, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
