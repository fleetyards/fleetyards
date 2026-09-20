# frozen_string_literal: true

require "test_helper"

# Where a connection starts and stops counting. The fan-out itself is covered by
# Presence::BroadcastTransitionJobTest — what matters here is that a signed-in
# socket registers, an anonymous one does not, and a reload stays quiet.
class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  # Devise puts the identities on the Rack env rather than in the session, so a
  # connection test has to supply the same thing warden would.
  class WardenDouble
    def initialize(user: nil, admin_user: nil)
      @identities = {user: user, admin_user: admin_user}
    end

    def user(scope)
      @identities[scope]
    end
  end

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

  def connect_as(user)
    connect env: {"warden" => WardenDouble.new(user: user)}
  end

  test "a signed-in connection counts as present and announces itself once" do
    connect_as(@user)

    assert UserPresence.online?(@user.id)
    assert_equal 1, Presence::BroadcastTransitionJob.jobs.size
    assert_equal [@user.id, true], Presence::BroadcastTransitionJob.jobs.first["args"]
  end

  test "an anonymous connection records nothing" do
    connect env: {"warden" => WardenDouble.new}

    assert_empty UserPresence.online_user_ids
    assert_equal 0, Presence::BroadcastTransitionJob.jobs.size
  end

  test "a second tab announces nothing" do
    connect_as(@user)
    Presence::BroadcastTransitionJob.jobs.clear

    connect_as(@user)

    assert_equal 0, Presence::BroadcastTransitionJob.jobs.size
  end

  test "each connection gets a handle of its own" do
    connect_as(@user)
    first = connection.presence_token

    connect_as(@user)

    refute_equal first, connection.presence_token
  end

  test "disconnecting leaves a grace tail and schedules the check" do
    connect_as(@user)

    disconnect

    assert UserPresence.online?(@user.id), "the grace tail should still count"
    assert_equal 1, Presence::OfflineCheckJob.jobs.size
    assert_equal [@user.id], Presence::OfflineCheckJob.jobs.first["args"]
  end

  test "the grace tail runs out on its own" do
    connect_as(@user)

    disconnect

    travel UserPresence::GRACE + 1.second do
      refute UserPresence.online?(@user.id)
    end
  end
end
