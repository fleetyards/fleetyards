# frozen_string_literal: true

require "asyncapi_helper"

class WishlistCreateChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "wishlist_create:{user_gid}", channel_class: WishlistCreateChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A vehicle was added to the user's wishlist" do
      operationId "receiveWishlistCreate"
      message ::V1::Schemas::Vehicles::Vehicle
    end
  end

  test "broadcasts the vehicle payload when one is added to the wishlist" do
    user = create(:user)

    payloads = assert_asyncapi_broadcast(params: {user_gid: user.to_gid_param}) do
      create(:vehicle, user:, wanted: true)
    end

    assert payloads.first["id"].present?
  end
end
