# frozen_string_literal: true

require 'discord/youtube_video'

class YoutubeUpdate < ApplicationRecord
  after_create :notify_discord

  def notify_discord
    Discord::YoutubeVideo.new(video_id: video_id).run
  end
end
