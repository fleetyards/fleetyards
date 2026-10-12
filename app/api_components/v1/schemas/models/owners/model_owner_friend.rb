# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Owners
        class ModelOwnerFriend
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              username: {type: :string},
              avatar: ::Shared::V1::Schemas::MediaFile,
              count: {type: :integer}
            },
            additionalProperties: false,
            required: %w[username count]
          })
        end
      end
    end
  end
end
