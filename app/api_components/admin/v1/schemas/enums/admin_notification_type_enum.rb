# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class AdminNotificationTypeEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::AdminNotification.notification_types.keys,
            "x-enumNames": ::AdminNotification.notification_types.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
