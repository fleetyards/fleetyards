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
            discordWebhookUrl: {type: [:string, :null]},
            enabledInAppEvents: {type: :array, items: {type: :string}}
          }
        })
      end
    end
  end
end
