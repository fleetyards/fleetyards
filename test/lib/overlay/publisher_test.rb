# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module Overlay
  class PublisherTest < ActiveSupport::TestCase
    setup do
      @client = Aws::S3::Client.new(stub_responses: true)
      @result = Export::Result.new(
        manifest: {schema: 1, channel: "live", sha256: "ab" * 32, file: "items.#{"ab" * 8}.json.gz", count: 0},
        items_gzip: "gz".b,
        file_name: "items.#{"ab" * 8}.json.gz"
      )
    end

    def publisher(stores: [Publisher::Store.new(client: @client, bucket: "public")])
      Publisher.new("live", stores:)
    end

    def requests(operation)
      @client.api_requests.select { |request| request[:operation_name] == operation }.map { |request| request[:params] }
    end

    test "uploads the items file before the manifest that names it, with their cache lifetimes" do
      @client.stub_responses(:get_object, "NoSuchKey")

      assert_equal :published, publisher.publish(@result)

      puts = requests(:put_object)
      assert_equal ["overlay/live/#{@result.file_name}", "overlay/live/manifest.json"], puts.map { |params| params[:key] }
      assert_equal Publisher::ITEMS_CACHE_CONTROL, puts.first[:cache_control]
      assert_equal Publisher::MANIFEST_CACHE_CONTROL, puts.last[:cache_control]
      assert_equal "public-read", puts.last[:acl]
      assert_equal @result.sha256, JSON.parse(puts.last[:body])["sha256"]
    end

    test "uploads nothing when the published manifest already says all of this" do
      @client.stub_responses(:get_object, {body: JSON.generate(@result.manifest.merge(generatedAt: "2026-01-01T00:00:00Z"))})

      assert_equal :unchanged, publisher.publish(@result)
      assert_empty requests(:put_object)
    end

    test "the same bytes under a new game version rewrite only the manifest" do
      @client.stub_responses(:get_object, {body: JSON.generate(@result.manifest.merge(gameVersion: "4.3.0"))})

      assert_equal :published, publisher.publish(@result.with(manifest: @result.manifest.merge(gameVersion: "4.4.0")))
      assert_equal ["overlay/live/manifest.json"], requests(:put_object).map { |params| params[:key] }
    end

    test "keeps the file the previous manifest named, however old it is" do
      previous = "items.#{"cd" * 8}.json.gz"
      @client.stub_responses(:get_object, {body: JSON.generate(sha256: "cd" * 32, file: previous)})
      @client.stub_responses(:list_objects_v2, {contents: [
        {key: "overlay/live/#{previous}", last_modified: 30.days.ago}
      ]})

      publisher.publish(@result)

      assert_empty requests(:delete_objects)
    end

    test "deletes items files older than a day, but never the one just published" do
      @client.stub_responses(:get_object, "NoSuchKey")
      @client.stub_responses(:list_objects_v2, {contents: [
        {key: "overlay/live/items.0000000000000000.json.gz", last_modified: 2.days.ago},
        {key: "overlay/live/items.1111111111111111.json.gz", last_modified: 1.hour.ago},
        {key: "overlay/live/#{@result.file_name}", last_modified: 3.days.ago}
      ]})

      publisher.publish(@result)

      deleted = requests(:delete_objects).flat_map { |params| params[:delete][:objects].map { |object| object[:key] } }
      assert_equal ["overlay/live/items.0000000000000000.json.gz"], deleted
    end

    test "writes the same files to a mirror, reading the published manifest only from the primary" do
      mirror = Aws::S3::Client.new(stub_responses: true)
      @client.stub_responses(:get_object, "NoSuchKey")

      assert_equal :published, publisher(stores: [
        Publisher::Store.new(client: @client, bucket: "primary"),
        Publisher::Store.new(client: mirror, bucket: "mirror")
      ]).publish(@result)

      written = ->(client) { client.api_requests.select { |r| r[:operation_name] == :put_object }.map { |r| r[:params].values_at(:bucket, :key) } }
      assert_equal [["primary", "overlay/live/#{@result.file_name}"], ["primary", "overlay/live/manifest.json"]], written.call(@client)
      assert_equal [["mirror", "overlay/live/#{@result.file_name}"], ["mirror", "overlay/live/manifest.json"]], written.call(mirror)
      assert_empty(mirror.api_requests.select { |r| r[:operation_name] == :get_object })
    end

    test "raises NotConfigured when the cloud service has no usable store" do
      Publisher.stubs(:settings).returns([{endpoint: nil, access_key_id: "a", secret_access_key: "b", bucket: "public", region: "unused"}])

      assert_raises(Publisher::NotConfigured) { Publisher.new("live").stores }
    end

    test "public URLs go through the storage CDN when there is one" do
      Rails.configuration.app.stubs(:storage_cdn_endpoint).returns("https://storage.test/")

      assert_equal "https://storage.test/overlay/ptu/manifest.json", Publisher.public_url("ptu", "manifest.json")
    end
  end
end
