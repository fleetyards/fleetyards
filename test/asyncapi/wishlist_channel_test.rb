# frozen_string_literal: true

require "asyncapi_helper"

class WishlistChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "wishlist:{user_gid}", channel_class: WishlistChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A wanted vehicle changed" do
      operationId "receiveWishlistUpdate"
      message ::V1::Schemas::Vehicles::Vehicle
    end
  end

  test "broadcasts the vehicle payload when a wanted vehicle changes" do
    vehicle = create(:vehicle, wanted: true)

    payloads = assert_asyncapi_broadcast(params: {user_gid: vehicle.user.to_gid_param}) do
      vehicle.update!(name: "Renamed")
    end

    assert_equal "Renamed", payloads.first["name"]
  end
end
