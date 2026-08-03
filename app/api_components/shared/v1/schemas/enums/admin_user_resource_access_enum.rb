# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class AdminUserResourceAccessEnum
          include OpenapiRuby::Components::Base

          PRIVILEGES = %w[
            admins
            components
            features
            fleets
            images
            imports
            maintenance
            manufacturers
            model_modules
            models
            oauth_applications
            pghero
            rsi-api-status
            stats
            supporters
            users
            vehicles
            workers
          ].freeze

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
