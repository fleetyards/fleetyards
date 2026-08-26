# frozen_string_literal: true

module Oauth
  module V1
    module Schemas
      module Enums
        class OauthAuthorizationStatusEnum
          include OpenapiRuby::Components::Base

          VALUES = %w[redirect post].freeze

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
