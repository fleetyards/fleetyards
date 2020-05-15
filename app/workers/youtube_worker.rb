# frozen_string_literal: true

require 'youtube/video_loader'

class YoutubeWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['YOUTUBE_QUEUE'] || 'fleetyards_youtube_loader').to_sym

  def perform
    ::Youtube::VideoLoader.new.update
  end
end
