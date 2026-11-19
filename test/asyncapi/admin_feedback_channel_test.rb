# frozen_string_literal: true

require "asyncapi_helper"

class AdminFeedbackChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/admin/v1/schema"

  channel "admin_feedback:{admin_user_gid}", channel_class: AdminFeedbackChannel do
    parameter :admin_user_gid,
      description: "GlobalID param of the subscribed admin user, derived from the connection",
      client_supplied: false

    broadcast "A feedback conversation changed" do
      operationId "receiveAdminFeedbackUpdate"
      message ::Admin::V1::Schemas::Feedback
    end
  end

  test "broadcasts the conversation when the user replies" do
    admin_user = create(:admin_user, resource_access: [:feedback])
    feedback = create(:feedback)

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      create(:feedback_reply, feedback:, body: "The Carrack")
    end

    assert_equal ["The Carrack"], payloads.last["replies"].pluck("body")
  end
end
