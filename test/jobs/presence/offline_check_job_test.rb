# frozen_string_literal: true

require "test_helper"

class Presence::OfflineCheckJobTest < ActiveSupport::TestCase
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

  test "settles a user whose last connection has gone" do
    UserPresence.connect(@user.id, "tab-1")
    UserPresence.disconnect(@user.id, "tab-1")
    Presence::BroadcastTransitionJob.jobs.clear

    travel UserPresence::GRACE + 1.second do
      Presence::OfflineCheckJob.new.perform(@user.id)

      assert_equal [[@user.id, false, "connection"]],
        Presence::BroadcastTransitionJob.jobs.map { |job| job["args"] }
    end
  end

  test "a reload emits nothing" do
    UserPresence.connect(@user.id, "tab-1")
    UserPresence.disconnect(@user.id, "tab-1")

    travel 2.seconds do
      UserPresence.connect(@user.id, "tab-2")
    end

    Presence::BroadcastTransitionJob.jobs.clear

    travel UserPresence::GRACE + 1.second do
      Presence::OfflineCheckJob.new.perform(@user.id)

      assert_equal 0, Presence::BroadcastTransitionJob.jobs.size
    end
  end

  test "another user's disconnect is left for their own check" do
    other = create(:user)
    UserPresence.connect(@user.id, "tab-1")
    UserPresence.connect(other.id, "phone")
    UserPresence.disconnect(@user.id, "tab-1")
    UserPresence.disconnect(other.id, "phone")
    Presence::BroadcastTransitionJob.jobs.clear

    travel UserPresence::GRACE + 1.second do
      Presence::OfflineCheckJob.new.perform(@user.id)

      assert_equal [[@user.id, false, "connection"]],
        Presence::BroadcastTransitionJob.jobs.map { |job| job["args"] }
    end
  end
end
