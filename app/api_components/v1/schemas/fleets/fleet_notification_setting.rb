# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetNotificationSetting
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fleetId: {type: :string, format: :uuid},
            enabledInAppEvents: {
              type: :array,
              items: ::V1::Schemas::Enums::FleetNotificationInAppEventEnum
            },
            discordGuildId: {type: :string},
            discordChannelId: {type: :string},
            discordAnnouncementChannelId: {type: [:string, :null]},
            discordOfficersChannelId: {type: [:string, :null]},
            discordDigestWeekday: {type: [:integer, :null], minimum: 0, maximum: 6},
            discordDigestTime: {type: [:string, :null], pattern: "^([01][0-9]|2[0-3]):[0-5][0-9]$"},
            discordMemberRoleId: {type: :string},
            # discord_webhook_url is encrypted; never returned, only writable.
            discordWebhookConfigured: {type: :boolean}
          },
          required: %w[id fleetId enabledInAppEvents discordWebhookConfigured]
        })
      end
    end
  end
end
