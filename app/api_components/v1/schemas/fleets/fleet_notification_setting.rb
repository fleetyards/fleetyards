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
            # discord_webhook_url is encrypted; never returned, only writable.
            discordWebhookConfigured: {type: :boolean}
          },
          required: %w[id fleetId enabledInAppEvents discordWebhookConfigured]
        })
      end
    end
  end
end
