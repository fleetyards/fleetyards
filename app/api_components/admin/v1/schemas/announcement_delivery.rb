# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AnnouncementDelivery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            channel: ::Admin::V1::Schemas::Enums::AnnouncementChannelEnum,
            status: ::Admin::V1::Schemas::Enums::AnnouncementDeliveryStatusEnum,
            externalId: {type: :string},
            error: {type: :string},
            deliveredAt: {type: :string, format: "date-time"},
            attempts: {type: :integer}
          },
          additionalProperties: false,
          required: %w[channel status attempts]
        })
      end
    end
  end
end
