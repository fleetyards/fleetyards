# frozen_string_literal: true

require "test_helper"

# The switch is applied on read, so flipping it changes nothing a connection
# change would broadcast — which is exactly why the model has to say so itself.
class UserOnlineStatusTest < ActiveSupport::TestCase
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

  test "it defaults to on" do
    assert @user.show_online_status?
  end

  test "turning it off while connected corrects the rosters already showing the dot" do
    UserPresence.connect(@user.id, "tab-1")
    Presence::BroadcastTransitionJob.jobs.clear

    @user.update!(show_online_status: false)

    # Named as the preference, not as a connection: it is the one thing allowed
    # to reach a peer of somebody who has just opted out.
    assert_equal [[@user.id, true, "preference"]],
      Presence::BroadcastTransitionJob.jobs.map { |job| job["args"] }
  end

  test "turning it off while nothing is connected broadcasts nothing" do
    Presence::BroadcastTransitionJob.jobs.clear

    @user.update!(show_online_status: false)

    assert_equal 0, Presence::BroadcastTransitionJob.jobs.size
  end

  test "an unrelated update broadcasts nothing" do
    UserPresence.connect(@user.id, "tab-1")
    Presence::BroadcastTransitionJob.jobs.clear

    @user.update!(homepage: "https://example.test")

    assert_equal 0, Presence::BroadcastTransitionJob.jobs.size
  end
end
