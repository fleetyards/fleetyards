# frozen_string_literal: true

require "test_helper"

# Scanners send a Client-IP header that disagrees with X-Forwarded-For. Rails
# refuses to pick an address and raises, which is the client's doing.
class IpSpoofCheckTest < ActionDispatch::IntegrationTest
  test "conflicting client address headers are a bad request" do
    get "/api/", headers: {
      "HTTP_ACCEPT" => "application/json",
      "HTTP_CLIENT_IP" => "1.2.3.4",
      "HTTP_X_FORWARDED_FOR" => "5.6.7.8"
    }

    assert_response :bad_request
  end
end
