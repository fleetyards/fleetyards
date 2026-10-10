# frozen_string_literal: true

require "asyncapi_helper"

class UserNotificationsChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "user_notifications:{user_gid}", channel_class: UserNotificationsChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A notification addressed to one user, or notifications of theirs that were withdrawn" do
      operationId "receiveUserNotification"
      message ::V1::Schemas::Notification
      message ::Cable::V1::Schemas::NotificationsWithdrawnMessage
    end
  end

  test "broadcasts the notification payload when one is created" do
    user = create(:user)

    payloads = assert_asyncapi_broadcast(params: {user_gid: user.to_gid_param}) do
      Notification.notify!(user:, type: :hangar_create, title: "Ship added")
    end

    assert_equal "Ship added", payloads.first["title"]
  end

  test "broadcasts the withdrawn notifications when their fleet announcement is taken down" do
    user = create(:user)
    fleet = create(:fleet, members: [user])
    announcement = create(:fleet_announcement, fleet:)
    notification = create(:notification, user:, notification_type: "fleet_announcement_posted", record: announcement)

    payloads = assert_asyncapi_broadcast(params: {user_gid: user.to_gid_param}) do
      announcement.destroy!
    end

    assert_equal [notification.id], payloads.first["withdrawnIds"]
  end
end
