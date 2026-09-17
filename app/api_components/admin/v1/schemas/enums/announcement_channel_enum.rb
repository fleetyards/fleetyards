# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class AnnouncementChannelEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::AnnouncementDelivery.channels.keys,
            "x-enumNames": ::AnnouncementDelivery.channels.keys.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
