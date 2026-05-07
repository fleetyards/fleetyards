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
              email: {type: :string},
              rsiHandle: {type: :string},
              saleNotify: {type: :boolean},
              publicHangar: {type: :boolean},
              publicHangarLoaners: {type: :boolean},
              publicWishlist: {type: :boolean},
              hideOwner: {type: :boolean},
              tester: {type: :boolean},
              avatar: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
