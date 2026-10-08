# frozen_string_literal: true

class StarCitizenUpdate < ApplicationRecord
  after_create :notify_discord

  def notify_discord
    Discord::RsiNews.new(news: self).run
  end
end
