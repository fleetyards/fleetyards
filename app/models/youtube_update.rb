# frozen_string_literal: true

# == Schema Information
#
# Table name: youtube_updates
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  video_id   :string
#
require 'discord/youtube_video'

class YoutubeUpdate < ApplicationRecord
  after_create :notify_discord

  def notify_discord
    Discord::YoutubeVideo.new(video_id: video_id).run
  end
end
