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
            attempts: {type: :integer},
            url: {type: :string, format: :uri},
            engagementTrackable: {type: :boolean, description: "Whether counts are read back for this delivery"},
            engagement: ::Admin::V1::Schemas::AnnouncementEngagement,
            engagementFetchedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[channel status attempts engagementTrackable]
        })
      end
    end
  end
end
