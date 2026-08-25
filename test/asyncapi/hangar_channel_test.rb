# frozen_string_literal: true

require "asyncapi_helper"

class HangarChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "hangar:{user_gid}", channel_class: HangarChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A vehicle in the user's hangar changed" do
      operationId "receiveHangarUpdate"
      message ::V1::Schemas::Vehicles::Vehicle
    end
  end

  test "broadcasts the vehicle payload when a hangar vehicle changes" do
    vehicle = create(:vehicle)

    payloads = assert_asyncapi_broadcast(params: {user_gid: vehicle.user.to_gid_param}) do
      vehicle.update!(name: "Renamed Vehicle")
    end

    assert_equal "Renamed Vehicle", payloads.first["name"]
  end
end
