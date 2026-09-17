# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class AnnouncementDeliveryStatusEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::AnnouncementDelivery.statuses.keys,
            "x-enumNames": ::AnnouncementDelivery.statuses.keys.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
