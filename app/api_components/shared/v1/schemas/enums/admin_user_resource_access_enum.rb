# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class AdminUserResourceAccessEnum
          include OpenapiRuby::Components::Base

          PRIVILEGES = ::AdminUser::AVAILABLE_PRIVILEGES

          schema({
            type: :string,
            enum: PRIVILEGES,
            "x-enumNames": PRIVILEGES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
