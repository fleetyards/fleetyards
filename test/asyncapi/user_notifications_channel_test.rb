# frozen_string_literal: true

require "asyncapi_helper"

class UserNotificationsChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "user_notifications:{user_gid}", channel_class: UserNotificationsChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A notification addressed to one user" do
      operationId "receiveUserNotification"
      message ::V1::Schemas::Notification
    end
  end

  test "broadcasts the notification payload when one is created" do
    user = create(:user)

    payloads = assert_asyncapi_broadcast(params: {user_gid: user.to_gid_param}) do
      Notification.notify!(user:, type: :hangar_create, title: "Ship added")
    end

    assert_equal "Ship added", payloads.first["title"]
  end
end
