# frozen_string_literal: true

require "test_helper"

# Bluesky fetches this document from the client_id and rejects it unless the
# client_id it names is that same URL.
class Oauth::ClientMetadataTest < ActionDispatch::IntegrationTest
  JWK = {kty: "EC", crv: "P-256", x: "x", y: "y", kid: "key-1"}.to_json

  test "GET /oauth/client-metadata.json names the URL it is served from as its client_id" do
    Rails.application.credentials.stubs(:dig).with(:bluesky, :jwk).returns(JWK)

    get BLUESKY_CLIENT_ID

    assert_response :ok
    assert_equal BLUESKY_CLIENT_ID, response.parsed_body["client_id"]
    assert_equal ["#{FRONTEND_ENDPOINT}/users/auth/bluesky/callback"], response.parsed_body["redirect_uris"]
  end

  test "GET /oauth/client-metadata.json is not found without a key" do
    Rails.application.credentials.stubs(:dig).with(:bluesky, :jwk).returns(nil)

    get BLUESKY_CLIENT_ID

    assert_response :not_found
  end
end
