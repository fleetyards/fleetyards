# frozen_string_literal: true

require "asyncapi_helper"

class AdminPresenceChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/admin/v1/schema"

  channel "admin_presence:{admin_user_gid}", channel_class: AdminPresenceChannel do
    parameter :admin_user_gid,
      description: "GlobalID param of the subscribed admin user, derived from the connection",
      client_supplied: false

    broadcast "A user came online or went offline" do
      operationId "receiveAdminUserPresence"
      message ::Cable::V1::Schemas::UserPresenceMessage
    end
  end

  setup do
    UserPresence.reset!
  end

  teardown do
    UserPresence.reset!
  end

  test "an admin sees the transition even with the flag off" do
    admin_user = create(:admin_user)
    user = create(:user)

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      Presence::BroadcastTransitionJob.new.perform(user.id, true)
    end

    assert_equal user.id, payloads.first["userId"]
    assert payloads.first["online"]
  end

  test "an admin sees the truth about a user who opted out" do
    admin_user = create(:admin_user)
    user = create(:user, show_online_status: false)

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      Presence::BroadcastTransitionJob.new.perform(user.id, true)
    end

    assert payloads.first["online"]
  end
end
