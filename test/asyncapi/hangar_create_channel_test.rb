# frozen_string_literal: true

require "asyncapi_helper"

class HangarCreateChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "hangar_create:{user_gid}", channel_class: HangarCreateChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A vehicle was added to the user's hangar" do
      operationId "receiveHangarCreate"
      message ::V1::Schemas::Vehicles::Vehicle
    end
  end

  test "broadcasts the vehicle payload when one is added to the hangar" do
    user = create(:user)

    payloads = assert_asyncapi_broadcast(params: {user_gid: user.to_gid_param}) do
      create(:vehicle, user:, wanted: false)
    end

    assert payloads.first["id"].present?
  end
end
