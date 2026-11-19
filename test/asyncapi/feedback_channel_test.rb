# frozen_string_literal: true

require "asyncapi_helper"

class FeedbackChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "feedback:{user_gid}", channel_class: FeedbackChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A conversation about the user's feedback changed" do
      operationId "receiveFeedbackUpdate"
      message ::V1::Schemas::Feedbacks::Feedback
    end
  end

  test "broadcasts the conversation when an admin replies" do
    feedback = create(:feedback)

    payloads = assert_asyncapi_broadcast(params: {user_gid: feedback.user.to_gid_param}) do
      create(:feedback_reply, feedback:, from_admin: true, body: "Which ship?")
    end

    assert_equal feedback.id, payloads.last["id"]
    assert_equal ["Which ship?"], payloads.last["replies"].pluck("body")
  end

  test "broadcasts the status when the feedback is resolved" do
    feedback = create(:feedback)

    payloads = assert_asyncapi_broadcast(params: {user_gid: feedback.user.to_gid_param}) do
      feedback.resolve!
    end

    assert_equal "resolved", payloads.last["state"]
  end
end
