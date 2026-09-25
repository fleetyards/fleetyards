# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetNotificationSettingUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            discordGuildId: {type: [:string, :null]},
            discordChannelId: {type: [:string, :null]},
            discordAnnouncementChannelId: {type: [:string, :null]},
            discordOfficersChannelId: {type: [:string, :null]},
            discordDigestWeekday: {type: [:integer, :null], minimum: 0, maximum: 6},
            discordDigestTime: {type: [:string, :null]},
            discordDigestTimezone: {type: [:string, :null]},
            discordMemberRoleId: {type: [:string, :null]},
            discordWebhookUrl: {type: [:string, :null]},
            enabledInAppEvents: {type: :array, items: {type: :string}}
          }
        })
      end
    end
  end
end
