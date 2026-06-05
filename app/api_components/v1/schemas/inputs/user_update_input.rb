# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class UserUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            avatar: {type: [:string, :null]},
            removeAvatar: {type: :boolean},
            rsiHandle: {type: [:string, :null]},
            homepage: {type: [:string, :null]},
            discord: {type: [:string, :null]},
            youtube: {type: [:string, :null]},
            guilded: {type: [:string, :null]},
            twitch: {type: [:string, :null]},
            saleNotify: {type: :boolean},
            publicHangar: {type: :boolean},
            publicHangarLoaners: {type: :boolean},
            publicHangarStats: {type: :boolean},
            publicWishlist: {type: :boolean},
            hideOwner: {type: :boolean},
            location: {type: [:string, :null]},
            currentSystem: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
