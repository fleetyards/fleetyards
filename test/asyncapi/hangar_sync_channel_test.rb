# frozen_string_literal: true

require "asyncapi_helper"

class HangarSyncChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "hangar_sync:{user_gid}", channel_class: HangarSyncChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "Outcome of an RSI hangar sync run" do
      operationId "receiveHangarSyncResult"
      message ::Cable::V1::Schemas::HangarSyncFinishedMessage
      message ::Cable::V1::Schemas::HangarSyncFailedMessage
    end
  end

  test "broadcasts the finished payload after a sync run" do
    user = create(:user)

    payloads = assert_asyncapi_broadcast(params: {user_gid: user.to_gid_param}) do
      HangarSync.new([]).run(user.id)
    end

    assert_equal "finished", payloads.first["status"]
  end
end
