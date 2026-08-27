# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Sorts
        class AdminNotificationSortEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::AdminNotification::ALLOWED_SORTING_PARAMS,
            "x-enumNames": ::AdminNotification::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
