# frozen_string_literal: true

require "test_helper"

# The backstop for connections that ended without a callback. A killed worker
# runs nothing at all, so the only thing left is that the score stops being
# refreshed — and an expiring score fires no event.
class Presence::SweepJobTest < ActiveSupport::TestCase
  setup do
    UserPresence.reset!
    Sidekiq::Testing.fake!
    Sidekiq::Job.clear_all

    @user = create(:user)
  end

  teardown do
    UserPresence.reset!
    Sidekiq::Job.clear_all
  end

  test "a connection nothing beats for falls offline once its TTL has run out" do
    UserPresence.connect(@user.id, "killed-worker")
    Presence::BroadcastTransitionJob.jobs.clear

    Presence::SweepJob.new.perform

    assert_equal 0, Presence::BroadcastTransitionJob.jobs.size

    travel UserPresence::TTL + 1.second do
      Presence::SweepJob.new.perform

      assert_equal [[@user.id, "connection"]],
        Presence::BroadcastTransitionJob.jobs.map { |job| job["args"] }
    end
  end

  test "it announces a connection nothing else got to announce" do
    UserPresence.heartbeat(@user.id, "beat-first")

    Presence::SweepJob.new.perform

    assert_equal [[@user.id, "connection"]],
      Presence::BroadcastTransitionJob.jobs.map { |job| job["args"] }
  end

  # The announced set moves before anything is enqueued, so an enqueue that
  # fails has to be put back or the next pass would see the deduplicated state
  # and say nothing at all — and reconcile commits the whole batch, so stopping
  # at the first failure would strand every transition after it.
  test "every enqueue that fails is left for the next pass" do
    other = create(:user)
    UserPresence.connect(@user.id, "tab-1")
    UserPresence.connect(other.id, "phone")
    Presence::BroadcastTransitionJob.jobs.clear

    travel UserPresence::TTL + 1.second do
      Presence::BroadcastTransitionJob.stubs(:perform_async).raises(RuntimeError, "queue down")

      assert_raises(Presence::EmitsTransitions::EnqueueFailed) { Presence::SweepJob.new.perform }

      Presence::BroadcastTransitionJob.unstub(:perform_async)

      Presence::SweepJob.new.perform

      assert_equal [@user.id, other.id].sort,
        Presence::BroadcastTransitionJob.jobs.map { |job| job["args"].first }.sort
    end
  end

  test "a second pass emits nothing" do
    UserPresence.connect(@user.id, "tab-1")
    Presence::BroadcastTransitionJob.jobs.clear

    2.times { Presence::SweepJob.new.perform }

    assert_equal 0, Presence::BroadcastTransitionJob.jobs.size
  end
end
