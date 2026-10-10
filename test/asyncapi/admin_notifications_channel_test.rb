# frozen_string_literal: true

require "asyncapi_helper"

class AdminNotificationsChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/admin/v1/schema"

  channel "admin_notifications:{admin_user_gid}", channel_class: AdminNotificationsChannel do
    parameter :admin_user_gid,
      description: "GlobalID param of the subscribed admin user, derived from the connection",
      client_supplied: false

    broadcast "A notification addressed to one admin user, or notifications of theirs that were read, archived or deleted" do
      operationId "receiveAdminNotification"
      message ::Admin::V1::Schemas::AdminNotification
      message ::Cable::V1::Schemas::AdminNotificationsSettledMessage
    end
  end

  test "broadcasts the notification payload to an admin with access" do
    admin_user = create(:admin_user, resource_access: [:models])

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      AdminNotification.notify!(type: :paints_import, title: "Paints Import Results")
    end

    assert_equal "Paints Import Results", payloads.first["title"]
  end

  test "broadcasts the ids of the notifications that were settled" do
    admin_user = create(:admin_user, resource_access: [:models])
    notification = create(:admin_notification, admin_user:)

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      AdminNotification.broadcast_settled(admin_user, [notification.id])
    end

    assert_equal [notification.id], payloads.first["settledIds"]
  end
end
