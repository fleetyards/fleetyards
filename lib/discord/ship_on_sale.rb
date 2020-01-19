# frozen_string_literal: true

require 'discord/webhook'

# rubocop:disable Naming/AccessorMethodName
module Discord
  class ShipOnSale < ::Discord::Webhook
    include ActionView::Helpers::NumberHelper

    private def model
      options[:model]
    end

    private def get_title
      I18n.t('discord.ship_on_sale.title', model: model.name)
    end

    private def get_message
      I18n.t('discord.ship_on_sale.message', price: number_to_currency(model.pledge_price))
    end

    private def get_url
      frontend_url("ships/#{model.slug}")
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
