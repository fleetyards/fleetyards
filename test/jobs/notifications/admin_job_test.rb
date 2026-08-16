# frozen_string_literal: true

require "test_helper"

module Notifications
  class AdminJobTest < ActiveJob::TestCase
    test "#perform sends weekly admin email with stats" do
      captured_stats = nil
      AdminMailer.stubs(:weekly).with do |stats|
        captured_stats = stats
        true
      end.returns(stub(deliver_later: true))

      ::Notifications::AdminJob.new.perform

      assert_includes captured_stats.keys, :registrations
      assert_includes captured_stats.keys, :ships
      assert_includes captured_stats.keys, :vehicles
      assert_includes captured_stats.keys, :wishes
      assert_includes captured_stats.keys, :fleets
    end
  end
end
