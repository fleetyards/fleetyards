# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

# OmniAuth test mode skips the request phase, so the callback tests never run
# discovery; this one exercises the Faraday JSON parsing it depends on.
class CitizenidDiscoveryTest < ActiveSupport::TestCase
  ISSUER = "https://citizenid.space/"

  test "discovers the provider configuration" do
    stub_request(:get, "#{ISSUER}.well-known/openid-configuration")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json;charset=UTF-8"},
        body: {
          issuer: ISSUER,
          authorization_endpoint: "#{ISSUER}connect/authorize",
          token_endpoint: "#{ISSUER}connect/token",
          userinfo_endpoint: "#{ISSUER}connect/userinfo",
          jwks_uri: "#{ISSUER}.well-known/jwks",
          response_types_supported: ["code"],
          subject_types_supported: ["public"],
          id_token_signing_alg_values_supported: ["RS256"]
        }.to_json
      )

    config = OpenIDConnect::Discovery::Provider::Config.discover!(ISSUER)

    assert_equal "#{ISSUER}connect/authorize", config.authorization_endpoint
  end
end
