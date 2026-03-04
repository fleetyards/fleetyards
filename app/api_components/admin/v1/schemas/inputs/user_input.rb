# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class UserInput
          include Rswag::SchemaComponents::Component

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
              tester: {type: :boolean}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
