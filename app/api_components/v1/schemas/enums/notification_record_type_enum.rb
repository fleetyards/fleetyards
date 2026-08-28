# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class NotificationRecordTypeEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::NotificationRecordReference::TYPES,
          "x-enumNames": ::NotificationRecordReference::TYPES.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
