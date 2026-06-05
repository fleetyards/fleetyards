# frozen_string_literal: true

require "test_helper"

module Loaders
  class YoutubeJobTest < ActiveJob::TestCase
    test "#perform runs the youtube video loader" do
      loader = mock("Youtube::VideoLoader")
      loader.expects(:update)
      Youtube::VideoLoader.stubs(:new).returns(loader)

      ::Loaders::YoutubeJob.new.perform
    end
  end
end
