# frozen_string_literal: true

require "asyncapi_helper"

class OnSaleHangarChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "on_sale_hangar:{user_gid}", channel_class: OnSaleHangarChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A vehicle the user owns went on sale" do
      operationId "receiveOnSaleHangar"
      message ::V1::Schemas::Vehicles::Vehicle
    end
  end
end
