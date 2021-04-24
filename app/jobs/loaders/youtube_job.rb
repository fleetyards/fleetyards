# frozen_string_literal: true

require 'youtube/video_loader'

module Loaders
  class YoutubeJob < ::Loaders::BaseJob
    def perform
      ::Youtube::VideoLoader.new.update
    end
  end
end
