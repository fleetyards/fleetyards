# frozen_string_literal: true

require "test_helper"

class OmniAuth::Strategies::BlueskyTest < ActiveSupport::TestCase
  DID = "did:plc:abc123"

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

  private def strategy
    @strategy ||= OmniAuth::Strategies::Bluesky.new(nil, "client-id", "").tap do |s|
      s.access_token = OAuth2::AccessToken.from_hash(s.client, {"access_token" => "token", "sub" => DID})
    end
  end
end
