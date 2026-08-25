# frozen_string_literal: true

require "asyncapi_helper"

class ModelsChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "models", channel_class: ModelsChannel do
    broadcast "A ship model changed" do
      operationId "receiveModelUpdate"
      message ::V1::Schemas::Models::Model
    end
  end

  test "broadcasts the model payload when a model changes" do
    model = create(:model)

    payloads = assert_asyncapi_broadcast do
      model.update!(name: "Renamed Model")
    end

    assert_equal "Renamed Model", payloads.first["name"]
  end
end
