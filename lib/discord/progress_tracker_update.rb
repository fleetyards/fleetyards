# frozen_string_literal: true

require 'discord/webhook'

# rubocop:disable Naming/AccessorMethodName
module Discord
  class ProgressTrackerUpdate < ::Discord::Webhook
    private def get_title
      I18n.t('discord.progress_tracker_update.title')
    end

    private def get_message
      I18n.t('discord.progress_tracker_update.message', changes: options[:changes])
    end

    private def get_url
      frontend_url('roadmap/changes')
    end

    private def get_webhook_endpoint
      Rails.application.credentials.discord_progress_tracker_updates_endpoint
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
