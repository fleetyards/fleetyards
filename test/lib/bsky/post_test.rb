# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "bsky/post"

module Bsky
  class PostTest < ActiveSupport::TestCase
    PDS = "https://bsky.social"

    setup do
      Rails.application.credentials.stubs(:bsky_handle).returns("fleetyards.net")
      Rails.application.credentials.stubs(:bsky_app_password).returns("app-password")
      Rails.application.credentials.stubs(:bsky_endpoint).returns(PDS)

      stub_request(:post, "#{PDS}/xrpc/com.atproto.server.createSession")
        .to_return(
          status: 200,
          body: {accessJwt: "token", refreshJwt: "refresh", did: "did:plc:fleetyards"}.to_json,
          headers: {"Content-Type" => "application/json"}
        )
    end

    test ".configured? needs all three credentials" do
      assert Bsky::Post.configured?

      Rails.application.credentials.stubs(:bsky_endpoint).returns(nil)

      refute Bsky::Post.configured?
    end

    test "#create posts the text and returns the record's AT URI" do
      uri = "at://did:plc:fleetyards/app.bsky.feed.post/abc"
      request = stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(
          status: 200,
          body: {uri: uri, cid: "cid"}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      assert_equal uri, Bsky::Post.new.create("Hello")
      assert_requested request
    end

    test "#create raises when Bluesky rejects the post" do
      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(status: 400, body: {error: "InvalidRequest"}.to_json, headers: {"Content-Type" => "application/json"})

      assert_raises(Bsky::Post::Error) { Bsky::Post.new.create("Hello") }
    end

    # No session is opened until something posts, so an install with no
    # credentials can still name the class.
    test "the session is not opened by the constructor" do
      Rails.application.credentials.stubs(:bsky_handle).returns(nil)

      assert_nothing_raised { Bsky::Post.new }
    end
  end
end
