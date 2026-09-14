# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FriendshipCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            username: {type: :string}
          },
          additionalProperties: false,
          required: %w[username]
        })
      end
    end
  end
end
