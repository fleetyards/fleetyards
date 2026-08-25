# frozen_string_literal: true

require "asyncapi_helper"

class AppVersionChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "app_version", channel_class: AppVersionChannel do
    broadcast "A new application version was deployed" do
      operationId "receiveAppVersion"
      message ::Cable::V1::Schemas::AppVersionMessage
    end
  end

  test "broadcasts the version payload on deploy" do
    payloads = assert_asyncapi_broadcast do
      ::Notifications::AppVersionJob.new.perform
    end

    assert_equal Fleetyards::VERSION, payloads.first["version"]
  end
end
