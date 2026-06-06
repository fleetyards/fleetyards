# frozen_string_literal: true

require "test_helper"

module Notifications
  class AppVersionJobTest < ActiveJob::TestCase
    test "#perform broadcasts app version via ActionCable" do
      ActionCable.server.expects(:broadcast).with(
        "app_version",
        {version: Fleetyards::VERSION, codename: Fleetyards::CODENAME}.to_json
      )

      ::Notifications::AppVersionJob.new.perform
    end
  end
end
