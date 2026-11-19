# frozen_string_literal: true

require "test_helper"

class FeedbackChannelSubscribeTest < ActionCable::Channel::TestCase
  tests FeedbackChannel

  test "refuses a connection without a user" do
    stub_connection(current_user: nil, current_admin_user: nil)

    subscribe

    assert subscription.rejected?
  end
end
