# frozen_string_literal: true

require 'discord/webhook'

# rubocop:disable Naming/AccessorMethodName
module Discord
  class RoadmapUpdate < ::Discord::Webhook
    private def get_title
      I18n.t('discord.roadmap_update.title')
    end

    private def get_message
      I18n.t('discord.roadmap_update.message', changes: options[:changes])
    end

    private def get_url
      frontend_url('roadmap/changes')
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
