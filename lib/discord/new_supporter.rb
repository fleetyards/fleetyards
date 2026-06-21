# frozen_string_literal: true

require "discord/webhook"

# rubocop:disable Naming/AccessorMethodName
module Discord
  class NewSupporter < ::Discord::Webhook
    private def supporter
      options[:supporter]
    end

    private def get_webhook_endpoint
      Rails.application.credentials.discord_admin_endpoint
    end

    private def get_title
      I18n.t("discord.new_supporter.title")
    end

    private def get_message
      I18n.t("discord.new_supporter.message", name: supporter.display_name, amount: supporter.formatted_amount)
    end

    private def get_url
    end

    private def allowed_mentions
      {parse: []}
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
