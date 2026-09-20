# frozen_string_literal: true

require "test_helper"

class UserPresenceChannelTest < ActionCable::Channel::TestCase
  setup do
    UserPresence.reset!
    @user = create(:user)
  end

  teardown do
    UserPresence.reset!
  end

  def stub_signed_in_connection(token: "tab-1")
    stub_connection(current_user: @user)
    connection.define_singleton_method(:presence_token) { token }
  end

  test "rejects a connection with nobody signed in" do
    stub_connection(current_user: nil)

    subscribe

    assert subscription.rejected?
  end

  test "streams for the signed-in user" do
    stub_signed_in_connection

    subscribe

    assert_has_stream_for @user
  end

  test "the heartbeat refreshes this connection past the TTL" do
    stub_signed_in_connection
    subscribe

    UserPresence.connect(@user.id, "tab-1")

    travel UserPresence::HEARTBEAT_INTERVAL do
      subscription.send(:heartbeat)
    end

    travel UserPresence::TTL + 1.second do
      assert UserPresence.online?(@user.id)
    end
  end

  test "the heartbeat registers a connection the store has already forgotten" do
    stub_signed_in_connection
    subscribe

    subscription.send(:heartbeat)

    assert UserPresence.online?(@user.id)
  end
end
