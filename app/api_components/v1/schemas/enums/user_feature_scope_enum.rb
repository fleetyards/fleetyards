# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class UserFeatureScopeEnum
        include OpenapiRuby::Components::Base

        VALUES = ::FeatureSetting::SELF_SERVICE_SCOPES.freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
