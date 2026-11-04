# frozen_string_literal: true

require "test_helper"

class IpSpoofCheckTest < ActionDispatch::IntegrationTest
  CONFLICTING = {
    "HTTP_CLIENT_IP" => "1.2.3.4",
    "HTTP_X_FORWARDED_FOR" => "5.6.7.8"
  }.freeze

  ["/", "/wp-login.php", "/api/"].each do |path|
    test "conflicting client address headers on #{path} are a bad request" do
      get path, headers: CONFLICTING

      assert_response :bad_request
      assert_equal "Bad Request", response.body
    end
  end

  test "a forwarded address alone is served" do
    get "/api/", headers: {"HTTP_ACCEPT" => "application/json", "HTTP_X_FORWARDED_FOR" => "5.6.7.8"}

    assert_response :success
  end

  test "agreeing client address headers are served" do
    get "/api/", headers: {
      "HTTP_ACCEPT" => "application/json",
      "HTTP_CLIENT_IP" => "5.6.7.8",
      "HTTP_X_FORWARDED_FOR" => "5.6.7.8"
    }

    assert_response :success
  end
end
