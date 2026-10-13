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

      post = Bsky::Post.new.create("Hello")

      assert_equal uri, post.uri
      assert_equal "cid", post.cid
      assert_requested request
    end

    # bskyrb's own helper points root and parent at the same post, which turns
    # a three-post thread into two threads of two.
    test "#create keeps the thread root while the parent moves along" do
      root = Bsky::Post::Record.new("at://root", "root-cid")
      parent = Bsky::Post::Record.new("at://second", "second-cid")

      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(status: 200, body: {uri: "at://third", cid: "third-cid"}.to_json, headers: {"Content-Type" => "application/json"})

      Bsky::Post.new.create("Third", root:, parent:)

      assert_requested(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord") { |request|
        reply = JSON.parse(request.body).dig("record", "reply")

        reply["root"]["uri"] == "at://root" && reply["parent"]["uri"] == "at://second"
      }
    end

    test "#create writes no reply for the first post of a thread" do
      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(status: 200, body: {uri: "at://first", cid: "cid"}.to_json, headers: {"Content-Type" => "application/json"})

      Bsky::Post.new.create("First")

      assert_requested(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord") { |request|
        !JSON.parse(request.body)["record"].key?("reply")
      }
    end

    test "#create makes links and hashtags clickable" do
      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(status: 200, body: {uri: "at://first", cid: "cid"}.to_json, headers: {"Content-Type" => "application/json"})

      Bsky::Post.new.create("Carrack\nhttps://fleetyards.net\n#starcitizen")

      assert_requested(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord") { |request|
        features = JSON.parse(request.body).dig("record", "facets").map { |facet| facet["features"].first["$type"] }

        features == ["app.bsky.richtext.facet#link", "app.bsky.richtext.facet#tag"]
      }
    end

    test "#create writes no facets for plain text" do
      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(status: 200, body: {uri: "at://first", cid: "cid"}.to_json, headers: {"Content-Type" => "application/json"})

      Bsky::Post.new.create("Hello")

      assert_requested(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord") { |request|
        !JSON.parse(request.body)["record"].key?("facets")
      }
    end

    test "#create attaches a link card with an uploaded thumbnail" do
      blob = {"$type" => "blob", "ref" => {"$link" => "bafy"}, "mimeType" => "image/jpeg", "size" => 4}
      upload = stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.uploadBlob")
        .with(body: "jpeg", headers: {"Content-Type" => "image/jpeg", "Authorization" => "Bearer token"})
        .to_return(status: 200, body: {blob:}.to_json, headers: {"Content-Type" => "application/json"})
      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(status: 200, body: {uri: "at://first", cid: "cid"}.to_json, headers: {"Content-Type" => "application/json"})

      Bsky::Post.new.create("Carrack", link_card: link_card(image: "jpeg"))

      assert_requested upload
      assert_requested(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord") { |request|
        embed = JSON.parse(request.body).dig("record", "embed")

        embed["$type"] == "app.bsky.embed.external" &&
          embed["external"] == {
            "uri" => "https://fleetyards.net/ships/carrack",
            "title" => "Anvil Carrack",
            "description" => "Explorer",
            "thumb" => blob
          }
      }
    end

    test "#create posts the card without a thumbnail when the upload is refused" do
      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.uploadBlob")
        .to_return(status: 400, body: {error: "InvalidRequest"}.to_json, headers: {"Content-Type" => "application/json"})
      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(status: 200, body: {uri: "at://first", cid: "cid"}.to_json, headers: {"Content-Type" => "application/json"})
      Appsignal.expects(:report_error).with(instance_of(Bsky::Post::Error))

      Bsky::Post.new.create("Carrack", link_card: link_card(image: "jpeg"))

      assert_requested(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord") { |request|
        external = JSON.parse(request.body).dig("record", "embed", "external")

        external["uri"] == "https://fleetyards.net/ships/carrack" && !external.key?("thumb")
      }
    end

    test "#create does not upload a thumbnail over Bluesky's size limit" do
      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(status: 200, body: {uri: "at://first", cid: "cid"}.to_json, headers: {"Content-Type" => "application/json"})

      Bsky::Post.new.create("Carrack", link_card: link_card(image: "x" * (Bsky::Post::MAX_THUMB_BYTES + 1)))

      assert_not_requested(:post, "#{PDS}/xrpc/com.atproto.repo.uploadBlob")
    end

    test "#create raises when Bluesky rejects the post" do
      stub_request(:post, "#{PDS}/xrpc/com.atproto.repo.createRecord")
        .to_return(status: 400, body: {error: "InvalidRequest"}.to_json, headers: {"Content-Type" => "application/json"})

      assert_raises(Bsky::Post::Error) { Bsky::Post.new.create("Hello") }
    end

    private def link_card(image:)
      Bsky::Post::LinkCard.new(
        uri: "https://fleetyards.net/ships/carrack",
        title: "Anvil Carrack",
        description: "Explorer",
        image:,
        content_type: "image/jpeg"
      )
    end

    # No session is opened until something posts, so an install with no
    # credentials can still name the class.
    test "the session is not opened by the constructor" do
      Rails.application.credentials.stubs(:bsky_handle).returns(nil)

      assert_nothing_raised { Bsky::Post.new }
    end
  end
end
