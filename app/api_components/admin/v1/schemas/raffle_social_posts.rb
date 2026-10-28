# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # The texts a raffle is announced with, ready to copy to X by hand.
      class RaffleSocialPosts
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            start: {type: :string},
            lastDay: {type: :string}
          },
          additionalProperties: false,
          required: %w[start lastDay]
        })
      end
    end
  end
end
