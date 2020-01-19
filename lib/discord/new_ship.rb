# frozen_string_literal: true

require 'discord/webhook'

# rubocop:disable Naming/AccessorMethodName
module Discord
  class NewShip < ::Discord::Webhook
    private def model
      options[:model]
    end

    private def get_title
      I18n.t('discord.new_ship.title')
    end

    private def get_message
      I18n.t('discord.new_ship.message', manufacturer: model.manufacturer.name, model: model.name)
    end

    private def get_url
      frontend_url("ships/#{model.slug}")
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
