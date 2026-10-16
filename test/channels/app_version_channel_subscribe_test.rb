# frozen_string_literal: true

require "test_helper"

# Named for the subscribe transmit rather than the channel: the asyncapi suite
# already owns `AppVersionChannelTest`.
class AppVersionChannelSubscribeTest < ActionCable::Channel::TestCase
  tests AppVersionChannel

  test "transmits the live version on subscribe" do
    stub_connection(current_user: nil)

    subscribe

    assert subscription.confirmed?
    assert_has_stream "app_version"
    assert_equal Fleetyards::VERSION, transmissions.last["version"]
  end
end
