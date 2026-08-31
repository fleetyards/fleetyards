# frozen_string_literal: true

require "test_helper"
require "discord/signature_verifier"

module Discord
  # Signs with a real Ed25519 keypair rather than stubbing the verifier: the
  # whole point of this class is that a genuine Discord signature verifies and
  # anything else does not, which a stub cannot demonstrate.
  class SignatureVerifierTest < ActiveSupport::TestCase
    setup do
      @key = OpenSSL::PKey.generate_key("ED25519")
      @public_key = @key.raw_public_key.unpack1("H*")
      @body = {type: 1}.to_json
      @timestamp = Time.current.to_i.to_s
      @verifier = ::Discord::SignatureVerifier.new(public_key: @public_key)
    end

    def sign(body: @body, timestamp: @timestamp, key: @key)
      key.sign(nil, "#{timestamp}#{body}").unpack1("H*")
    end

    test "accepts a signature made with the application's key" do
      assert @verifier.valid?(signature: sign, timestamp: @timestamp, body: @body)
    end

    test "rejects a body that changed after signing" do
      signature = sign

      refute @verifier.valid?(signature: signature, timestamp: @timestamp, body: '{"type":2}')
    end

    test "rejects a signature made with a different key" do
      signature = sign(key: OpenSSL::PKey.generate_key("ED25519"))

      refute @verifier.valid?(signature: signature, timestamp: @timestamp, body: @body)
    end

    test "rejects a timestamp the signature does not cover" do
      signature = sign

      refute @verifier.valid?(signature: signature, timestamp: 1.minute.ago.to_i.to_s, body: @body)
    end

    test "rejects a signature older than the replay window" do
      stale = (Time.current - ::Discord::SignatureVerifier::MAX_AGE - 1.minute).to_i.to_s

      refute @verifier.valid?(signature: sign(timestamp: stale), timestamp: stale, body: @body)
    end

    test "rejects a timestamp far in the future" do
      ahead = (Time.current + ::Discord::SignatureVerifier::MAX_AGE + 1.minute).to_i.to_s

      refute @verifier.valid?(signature: sign(timestamp: ahead), timestamp: ahead, body: @body)
    end

    test "rejects a signature that is not hex" do
      refute @verifier.valid?(signature: "not-a-signature", timestamp: @timestamp, body: @body)
    end

    test "rejects a signature of the wrong length" do
      refute @verifier.valid?(signature: "abcd", timestamp: @timestamp, body: @body)
    end

    test "rejects a blank signature" do
      refute @verifier.valid?(signature: nil, timestamp: @timestamp, body: @body)
    end

    test "rejects a non-numeric timestamp" do
      refute @verifier.valid?(signature: sign, timestamp: "yesterday", body: @body)
    end

    test "rejects everything while no public key is configured" do
      verifier = ::Discord::SignatureVerifier.new(public_key: nil)

      refute verifier.valid?(signature: sign, timestamp: @timestamp, body: @body)
    end
  end
end
