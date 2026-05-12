# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class NotificationTypeEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Notification.notification_types.keys,
            "x-enumNames": ::Notification.notification_types.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
