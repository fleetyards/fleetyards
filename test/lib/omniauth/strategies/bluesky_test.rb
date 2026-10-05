# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class OmniAuth::Strategies::BlueskyTest < ActiveSupport::TestCase
  DID = "did:plc:abc123"
  CLIENT_ID = "https://fleetyards.test/oauth/client-metadata.json"
  PAR_URL = "https://bsky.social/oauth/par"
  REQUEST_URI = "urn:ietf:params:oauth:request_uri:req-1"
  KEY = OpenSSL::PKey::EC.generate("prime256v1")

  test "#uid is the DID the token was issued for" do
    assert_equal DID, strategy.uid
  end

  test "#info nickname is the verified handle without the bsky.social suffix" do
    DIDKit::Resolver.any_instance.stubs(:get_verified_handle).with(DID).returns("pilot.bsky.social")

    assert_equal "pilot", strategy.info[:nickname]
  end

  test "#info nickname keeps a custom-domain handle" do
    DIDKit::Resolver.any_instance.stubs(:get_verified_handle).with(DID).returns("pilot.example.com")

    assert_equal "pilot.example.com", strategy.info[:nickname]
  end

  test "#info nickname is nil when the handle cannot be resolved" do
    DIDKit::Resolver.any_instance.stubs(:get_verified_handle).raises(StandardError, "plc.directory down")

    assert_nil strategy.info[:nickname]
  end

  test "#request_phase pushes the authorization request and redirects with its reference" do
    stub_request(:post, PAR_URL).to_return(json_response({request_uri: REQUEST_URI}, status: 201))

    status, headers = request_phase

    assert_equal 302, status
    location = URI.parse(headers["Location"])
    assert_equal "https://bsky.social/oauth/authorize", "#{location.scheme}://#{location.host}#{location.path}"
    assert_equal({"client_id" => CLIENT_ID, "request_uri" => REQUEST_URI}, URI.decode_www_form(location.query).to_h)
  end

  test "#request_phase signs the pushed request with the client key" do
    stub_request(:post, PAR_URL).to_return(json_response({request_uri: REQUEST_URI}, status: 201))

    request_phase

    assert_requested(:post, PAR_URL) { |request|
      params = URI.decode_www_form(request.body).to_h
      assertion, = JWT.decode(params["client_assertion"], KEY, true, algorithm: "ES256")
      dpop, = JWT.decode(request.headers["Dpop"], KEY, true, algorithm: "ES256")

      params.values_at("client_id", "response_type", "redirect_uri", "scope", "code_challenge_method") ==
        [CLIENT_ID, "code", "https://fleetyards.test/users/auth/bluesky/callback", "atproto transition:generic", "S256"] &&
        assertion.values_at("iss", "aud") == [CLIENT_ID, "https://bsky.social"] &&
        dpop.values_at("htm", "htu") == ["POST", PAR_URL]
    }
  end

  test "#request_phase retries with the DPoP nonce the server asks for" do
    stub_request(:post, PAR_URL)
      .to_return(json_response({error: "use_dpop_nonce"}, status: 400, headers: {"DPoP-Nonce" => "nonce-1"}))
      .then.to_return(json_response({request_uri: REQUEST_URI}, status: 201))

    status, = request_phase

    assert_equal 302, status
    assert_requested(:post, PAR_URL, times: 2)
    assert_requested(:post, PAR_URL) { |request|
      JWT.decode(request.headers["Dpop"], KEY, true, algorithm: "ES256").first["nonce"] == "nonce-1"
    }
  end

  test "#request_phase fails the login when the server refuses the request" do
    stub_request(:post, PAR_URL).to_return(json_response({error: "invalid_client"}, status: 400))
    OmniAuth.config.stubs(:on_failure).returns(->(env) { [401, {}, [env["omniauth.error.type"].to_s]] })

    status, _headers, body = request_phase

    assert_equal 401, status
    assert_equal ["pushed_authorization_request_failed"], body
  end

  private def strategy
    @strategy ||= OmniAuth::Strategies::Bluesky.new(nil, "client-id", "").tap do |s|
      s.access_token = OAuth2::AccessToken.from_hash(s.client, {"access_token" => "token", "sub" => DID})
    end
  end

  private def request_phase
    app = ->(_env) { [404, {}, []] }
    strategy = OmniAuth::Strategies::Bluesky.new(app, CLIENT_ID, "",
      private_key: KEY, client_jwk: {kid: "key-1"}, scope: "atproto transition:generic")
    env = Rack::MockRequest.env_for("https://fleetyards.test/users/auth/bluesky", method: "POST")
    env["rack.session"] = {}

    OmniAuth.config.stubs(:test_mode).returns(false)
    OmniAuth.config.stubs(:request_validation_phase).returns(nil)
    strategy.call(env)
  end

  private def json_response(body, status:, headers: {})
    {status: status, body: body.to_json, headers: {"Content-Type" => "application/json"}.merge(headers)}
  end
end
