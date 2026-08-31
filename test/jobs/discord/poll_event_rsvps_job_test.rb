# frozen_string_literal: true

require "test_helper"

module Discord
  class PollEventRsvpsJobTest < ActiveSupport::TestCase
    setup do
      @sync = mock("Discord::ScheduledEventRsvpSync")
      ::Discord::ScheduledEventRsvpSync.stubs(:new).returns(@sync)
    end

    def perform
      ::Discord::PollEventRsvpsJob.new.perform("scheduled-1", "guild-1")
    end

    test "runs the sync for the event" do
      @sync.stubs(:runnable?).returns(true)
      @sync.expects(:run!).returns(::Discord::ScheduledEventRsvpSync::Result.new(added: 1, removed: 0, skipped: 0))

      perform
    end

    test "does not run an unrunnable sync" do
      @sync.stubs(:runnable?).returns(false)
      @sync.expects(:run!).never

      perform
    end

    # A fleet whose bot lost Manage Events, or a channel it cannot see: real,
    # persistent, and not fixed by retrying every five minutes.
    test "a permission error is logged rather than retried" do
      @sync.stubs(:runnable?).returns(true)
      @sync.stubs(:run!).raises(::Discord::ApiClient::Error.new(403, "Missing Access"))

      assert_nothing_raised { perform }
    end

    test "a rate limit is retried" do
      @sync.stubs(:runnable?).returns(true)
      @sync.stubs(:run!).raises(::Discord::ApiClient::Error.new(429, "Too Many Requests"))

      assert_raises(::Discord::ApiClient::Error) { perform }
    end

    test "a Discord outage is retried" do
      @sync.stubs(:runnable?).returns(true)
      @sync.stubs(:run!).raises(::Discord::ApiClient::Error.new(503, "Service Unavailable"))

      assert_raises(::Discord::ApiClient::Error) { perform }
    end
  end
end
