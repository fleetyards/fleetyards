# frozen_string_literal: true

require "test_helper"

# Bots send header bytes that are not valid UTF-8. Rack's cookie parser splits
# the Cookie header with a regexp, which raises `ArgumentError: invalid byte
# sequence in UTF-8` -- a 500 in whichever code touched the session first.
class InvalidHeaderEncodingTest < ActionDispatch::IntegrationTest
  BROWSER_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
    "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

  test "a request with invalid bytes in the Cookie header is still served" do
    get "/api/", headers: {
      "HTTP_ACCEPT" => "application/json",
      "HTTP_USER_AGENT" => BROWSER_USER_AGENT,
      "HTTP_COOKIE" => "_fleetyards_session=abc\xFFdef".dup.force_encoding("UTF-8")
    }

    assert_response :success
  end

  test "invalid bytes in the Accept header end in content negotiation, not an error" do
    get "/api/", headers: {"HTTP_ACCEPT" => "not\xFFa/media-type".dup.force_encoding("UTF-8")}

    assert_response :not_acceptable
  end
end
