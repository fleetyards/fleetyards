# frozen_string_literal: true

require "test_helper"

class Api::RateLimitTest < ActionDispatch::IntegrationTest
  setup do
    @original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttles["api"].stubs(:limit).returns(1)
    host! "api.fleetyards.test"
  end

  teardown do
    Rack::Attack.cache.store = @original_store
  end

  test "anonymous API traffic is throttled per IP once the limit is exceeded" do
    get "/api/v1/models"
    assert_response :success

    get "/api/v1/models"
    assert_response :too_many_requests
  end

  test "a spoofed fleetyards.net referer no longer bypasses the throttle" do
    referer = {"HTTP_REFERER" => "https://fleetyards.net/"}

    get "/api/v1/models", headers: referer
    assert_response :success

    get "/api/v1/models", headers: referer
    assert_response :too_many_requests
  end

  test "the throttle keys on the proxy-resolved client, not the proxy" do
    # 10.0.0.254 is a trusted proxy by default, so RemoteIp walks past it to the
    # real client. Two clients behind the same proxy must be throttled apart.
    client_a = {"HTTP_X_FORWARDED_FOR" => "1.2.3.4, 10.0.0.254"}
    client_b = {"HTTP_X_FORWARDED_FOR" => "5.6.7.8, 10.0.0.254"}

    get "/api/v1/models", headers: client_a
    assert_response :success

    get "/api/v1/models", headers: client_a
    assert_response :too_many_requests

    get "/api/v1/models", headers: client_b
    assert_response :success
  end
end
