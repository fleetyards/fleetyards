# frozen_string_literal: true

require "asyncapi_helper"

class AdminNotificationsChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/admin/v1/schema"

  channel "admin_notifications:{admin_user_gid}", channel_class: AdminNotificationsChannel do
    parameter :admin_user_gid,
      description: "GlobalID param of the subscribed admin user, derived from the connection",
      client_supplied: false

    broadcast "A notification addressed to one admin user" do
      operationId "receiveAdminNotification"
      message ::Admin::V1::Schemas::AdminNotification
    end
  end

  test "broadcasts the notification payload to an admin with access" do
    admin_user = create(:admin_user, resource_access: [:models])

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      AdminNotification.notify!(type: :paints_import, title: "Paints Import Results")
    end

    assert_equal "Paints Import Results", payloads.first["title"]
  end
end
