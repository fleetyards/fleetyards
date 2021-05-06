# frozen_string_literal: true

require 'discord/webhook'

# rubocop:disable Naming/AccessorMethodName
module Discord
  class RsiNews < ::Discord::Webhook
    private def news
      options[:news]
    end

    private def get_title
      news.title
    end

    private def get_url
      news.url
    end

    private def get_webhook_endpoint
      Rails.application.credentials.discord_sc_updates_endpoint
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
