# frozen_string_literal: true

require "test_helper"
require "support/oauth_test_helpers"

class Api::RateLimitTest < ActionDispatch::IntegrationTest
  include OauthTestHelpers

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

  test "a signed-in user is counted apart from the address they share" do
    get "/api/v1/models"
    assert_response :success

    get "/api/v1/models"
    assert_response :too_many_requests

    sign_in create(:user)

    get "/api/v1/models"
    assert_response :success

    get "/api/v1/models"
    assert_response :too_many_requests
  end

  test "an OAuth client is counted against the token's user" do
    headers = oauth_headers_for(create(:user), scopes: "public")

    get "/api/v1/models"
    get "/api/v1/models"
    assert_response :too_many_requests

    get "/api/v1/models", headers: headers
    assert_response :success
  end

  test "a signed-in user gets the larger limit" do
    Rack::Attack.throttles["api"].unstub(:limit)

    get "/api/v1/models"
    assert_equal "5000", response.headers["X-RateLimit-Limit"]

    sign_in create(:user)

    get "/api/v1/models"
    assert_equal "10000", response.headers["X-RateLimit-Limit"]
  end

  test "image redirects do not spend the API budget" do
    Rack::Attack.throttles["files"].stubs(:limit).returns(1)
    blob_path = "#{ActiveStorage.routes_prefix}/blobs/redirect/missing/image.jpg"

    get blob_path
    get "/api/v1/models"
    assert_response :success

    get blob_path
    assert_response :too_many_requests
  end
end
