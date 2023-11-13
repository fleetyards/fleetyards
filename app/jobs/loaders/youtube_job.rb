# frozen_string_literal: true

module Loaders
  class YoutubeJob < ::Loaders::BaseJob
    def perform
      ::Youtube::VideoLoader.new.update
    end
  end
end
