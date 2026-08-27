# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetRoleResourceAccessEnum
        include OpenapiRuby::Components::Base

        PRIVILEGES = ::FleetRole.all_available_privileges.freeze

        schema({
          type: :string,
          enum: PRIVILEGES,
          "x-enumNames": PRIVILEGES.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
