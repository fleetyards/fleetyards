# frozen_string_literal: true

module V1
  module Schemas
    class NotificationRecord
      include OpenapiRuby::Components::Base

      # Identifiers only - enough to fetch the record the notification is about
      # and read its current state. Which fields are set depends on the type,
      # and which endpoint they belong to is decided by the notification type.
      schema({
        type: :object,
        properties: {
          type: ::V1::Schemas::Enums::NotificationRecordTypeEnum,
          id: {type: :string, format: :uuid},
          fleetSlug: {type: :string},
          username: {type: :string},
          eventSlug: {type: :string},
          inventorySlug: {type: :string}
        },
        additionalProperties: false,
        required: %w[type id]
      })
    end
  end
end
