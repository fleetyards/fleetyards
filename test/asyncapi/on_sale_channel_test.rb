# frozen_string_literal: true

require "asyncapi_helper"

class OnSaleChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "on_sale", channel_class: OnSaleChannel do
    broadcast "A ship model went on sale" do
      operationId "receiveOnSale"
      message ::V1::Schemas::Models::Model
    end
  end
end
