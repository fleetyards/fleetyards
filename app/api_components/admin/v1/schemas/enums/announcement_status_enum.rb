# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class AnnouncementStatusEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Announcement.statuses.keys,
            "x-enumNames": ::Announcement.statuses.keys.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
