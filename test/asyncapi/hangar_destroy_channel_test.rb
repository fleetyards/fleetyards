# frozen_string_literal: true

require "asyncapi_helper"

class HangarDestroyChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "hangar_destroy:{user_gid}", channel_class: HangarDestroyChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A vehicle was removed from the user's hangar" do
      operationId "receiveHangarDestroy"
      message ::V1::Schemas::Vehicles::Vehicle
    end
  end

  test "broadcasts the vehicle payload when one leaves the hangar" do
    vehicle = create(:vehicle, wanted: false)

    payloads = assert_asyncapi_broadcast(params: {user_gid: vehicle.user.to_gid_param}) do
      vehicle.destroy!
    end

    assert_equal vehicle.id, payloads.first["id"]
  end
end
