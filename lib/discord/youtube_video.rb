# frozen_string_literal: true

require 'discord/webhook'

# rubocop:disable Naming/AccessorMethodName
module Discord
  class YoutubeVideo < ::Discord::Webhook
    private def video_id
      options[:video_id]
    end

    private def get_title
      I18n.t('discord.youtube_video.title')
    end

    private def get_url
      "https://www.youtube.com/watch?v=#{video_id}"
    end

    private def get_webhook_endpoint
      Rails.application.secrets[:discord_sc_updates_endpoint]
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
