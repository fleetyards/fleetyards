# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "x_com/post"

module XCom
  class PostTest < ActiveSupport::TestCase
    setup do
      Rails.application.credentials.stubs(:x_api_key).returns("key")
      Rails.application.credentials.stubs(:x_api_secret).returns("secret")
      Rails.application.credentials.stubs(:x_access_token).returns("token")
      Rails.application.credentials.stubs(:x_access_token_secret).returns("token-secret")
    end

    test ".configured? needs all four secrets" do
      assert XCom::Post.configured?

      Rails.application.credentials.stubs(:x_access_token_secret).returns(nil)

      refute XCom::Post.configured?
    end

    test "#create posts the text and returns the new post's id" do
      request = stub_request(:post, XCom::Post::ENDPOINT)
        .with(body: {text: "Hello"}.to_json)
        .to_return(status: 201, body: {data: {id: "1234", text: "Hello"}}.to_json)

      assert_equal "1234", XCom::Post.new.create("Hello")
      assert_requested request
    end

    test "#create signs the request with OAuth 1.0a" do
      stub_request(:post, XCom::Post::ENDPOINT)
        .to_return(status: 201, body: {data: {id: "1"}}.to_json)

      XCom::Post.new.create("Hello")

      assert_requested(:post, XCom::Post::ENDPOINT) { |request|
        header = request.headers["Authorization"]

        header.start_with?("OAuth ") &&
          header.include?('oauth_consumer_key="key"') &&
          header.include?('oauth_signature_method="HMAC-SHA1"') &&
          header.include?("oauth_signature=")
      }
    end

    test "#create raises when X rejects the post" do
      stub_request(:post, XCom::Post::ENDPOINT).to_return(status: 403, body: "forbidden")

      error = assert_raises(XCom::Post::Error) { XCom::Post.new.create("Hello") }

      assert_equal 403, error.status
    end

    test "#create raises when the response carries no post id" do
      stub_request(:post, XCom::Post::ENDPOINT).to_return(status: 201, body: {data: {}}.to_json)

      assert_raises(XCom::Post::Error) { XCom::Post.new.create("Hello") }
    end

    test "#create raises rather than posting without credentials" do
      Rails.application.credentials.stubs(:x_api_key).returns(nil)

      assert_raises(XCom::Post::Error) { XCom::Post.new.create("Hello") }
    end
  end
end
