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
end
