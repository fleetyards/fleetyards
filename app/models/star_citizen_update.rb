# frozen_string_literal: true

require 'discord/rsi_news'

class StarCitizenUpdate < ApplicationRecord
  after_create :notify_discord

  def notify_discord
    Discord::RSINews.new(news: self).run
  end
end
