# frozen_string_literal: true

require "test_helper"

class AdminFeedbackChannelSubscribeTest < ActionCable::Channel::TestCase
  tests AdminFeedbackChannel

  test "streams for an admin who can read feedback" do
    admin_user = create(:admin_user, resource_access: [:feedback])
    stub_connection(current_user: nil, current_admin_user: admin_user)

    subscribe

    assert subscription.confirmed?
    assert_has_stream_for admin_user
  end

  test "refuses an admin without the feedback privilege" do
    stub_connection(current_user: nil, current_admin_user: create(:admin_user, resource_access: [:users]))

    subscribe

    assert subscription.rejected?
  end
end
