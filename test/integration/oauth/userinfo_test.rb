# frozen_string_literal: true

require "test_helper"
require "support/oauth_test_helpers"

# Plain integration test rather than the openapi DSL: declaring these responses
# would move the OAuth schema, and the point here is the status Doorkeeper's own
# metal controller returns, not the documented contract.
#
# `handle_auth_errors :raise` means Doorkeeper raises instead of rendering, and
# its metal endpoints inherit `base_metal_controller` -- so without one that
# rescues, an invalid token left the controller as a 500 rather than a 401.
class Oauth::UserinfoTest < ActionDispatch::IntegrationTest
  test "GET /oauth/userinfo rejects an unknown token instead of erroring" do
    get "/oauth/userinfo", headers: {"Authorization" => "Bearer totally-unknown-token"}

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body["code"]
  end

  test "GET /oauth/userinfo rejects a request with no token at all" do
    get "/oauth/userinfo"

    assert_response :unauthorized
  end

  test "GET /oauth/userinfo rejects a token without the openid scope" do
    get "/oauth/userinfo", headers: oauth_headers_for(create(:user), scopes: ["hangar"])

    assert_response :unauthorized
  end

  # The base controller swap reaches every Doorkeeper metal endpoint, so the
  # working path needs pinning too.
  test "GET /oauth/userinfo still answers a valid token" do
    user = create(:user)

    get "/oauth/userinfo", headers: oauth_headers_for(user, scopes: ["openid"])

    assert_response :success

    subject = response.parsed_body["sub"]

    # `subject` is configured as a salted digest per application rather than the
    # record id, so assert the shape and that the id did not leak.
    assert_match(/\A[0-9a-f]{64}\z/, subject)
    refute_equal user.id, subject
  end
end
