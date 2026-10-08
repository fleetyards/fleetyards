# frozen_string_literal: true

class YoutubeUpdate < ApplicationRecord
  after_create :notify_discord

  def notify_discord
    Discord::YoutubeVideo.new(video_id:).run
  end
end
