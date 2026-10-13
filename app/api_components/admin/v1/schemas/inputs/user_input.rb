# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class UserInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              username: {type: :string},
              displayName: {type: [:string, :null], maxLength: ::User::DISPLAY_NAME_LIMIT},
              email: {type: :string},
              rsiHandle: {type: :string},
              publicHangar: {type: :boolean},
              publicHangarLoaners: {type: :boolean},
              publicWishlist: {type: :boolean},
              hideOwner: {type: :boolean},
              tester: {type: :boolean},
              maintainer: {type: :boolean},
              avatar: {type: [:string, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
