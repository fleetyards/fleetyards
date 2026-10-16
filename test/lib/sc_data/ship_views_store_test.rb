# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module ScData
  class ShipViewsStoreTest < ActiveSupport::TestCase
    SETTINGS = {
      endpoint: "https://example.invalid",
      access_key_id: "key",
      secret_access_key: "secret",
      bucket: "fltyrd-sc"
    }.freeze

    setup do
      @client = Aws::S3::Client.new(stub_responses: true)
      @store = ::ScData::ShipViewsStore.new(client: @client, settings: SETTINGS)
    end

    private def requested_keys
      @client.api_requests
        .select { |request| request[:operation_name] == :get_object }
        .map { |request| request[:params][:key] }
    end

    test "#ships reads the index" do
      ships = {"crusader/ares-inferno" => {"slug" => "crus-ares-inferno", "files" => "abc", "updatedAt" => "2026-10-01T00:00:00Z"}}
      @client.stub_responses(:get_object, {body: {ships:}.to_json})

      assert_equal ships, @store.ships
      assert_equal ["ship-views/index.json"], requested_keys
    end

    test "#ships is empty for an index without ships" do
      @client.stub_responses(:get_object, {body: "{}"})

      assert_empty @store.ships
    end

    test "#listing reads a ship's files.json" do
      listing = {"slug" => "crus-ares-inferno", "path" => "crusader/ares-inferno", "files" => {}}
      @client.stub_responses(:get_object, {body: listing.to_json})

      assert_equal listing, @store.listing("crusader/ares-inferno")
      assert_equal ["ship-views/crusader/ares-inferno/files.json"], requested_keys
    end

    test "#fetch downloads a render into a tempfile" do
      @client.stub_responses(:get_object, {body: "render"})

      file = @store.fetch("crusader/ares-inferno", "flight_top.png")

      assert_equal "render", file.read
      assert_equal ".png", File.extname(file.path)
      assert_equal ["ship-views/crusader/ares-inferno/flight_top.png"], requested_keys
    ensure
      file&.close!
    end

    test "#fetch retries a failed download" do
      @store.stubs(:sleep)
      @client.stub_responses(:get_object, ["InternalError", {body: "render"}])

      file = @store.fetch("crusader/ares-inferno", "flight_top.png")

      assert_equal "render", file.read
    ensure
      file&.close!
    end
  end
end
