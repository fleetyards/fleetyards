# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Owners
        class ModelOwnerFriends
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              total: {type: :integer},
              items: {type: :array, items: ::V1::Schemas::Models::Owners::ModelOwnerFriend}
            },
            additionalProperties: false,
            required: %w[total items]
          })
        end
      end
    end
  end
end
