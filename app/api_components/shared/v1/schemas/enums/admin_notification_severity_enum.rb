# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class AdminNotificationSeverityEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::AdminNotification.severities.keys,
            "x-enumNames": ::AdminNotification.severities.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
