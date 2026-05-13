# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetNotificationSetting
        include Rswag::SchemaComponents::Component

        IN_APP_EVENTS = %w[
          fleet_event.published
          fleet_event.locked
          fleet_event.starting_soon
          fleet_event.cancelled
          fleet_event_signup.created
          fleet_event_signup.withdrawn
        ].freeze

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fleetId: {type: :string, format: :uuid},
            enabledInAppEvents: {
              type: :array,
              items: {type: :string, enum: IN_APP_EVENTS}
            },
            discordGuildId: {type: :string, nullable: true},
            discordChannelId: {type: :string, nullable: true},
            # discord_webhook_url is encrypted; never returned, only writable.
            discordWebhookConfigured: {type: :boolean}
          },
          required: %w[id fleetId enabledInAppEvents discordWebhookConfigured]
        })
      end
    end
  end
end
