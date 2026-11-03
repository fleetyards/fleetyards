# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module Overlay
  class PublisherTest < ActiveSupport::TestCase
    setup do
      @client = Aws::S3::Client.new(stub_responses: true)
      Publisher.stubs(:settings).returns(endpoint: "https://s3.test", access_key_id: "a", secret_access_key: "b", bucket: "public")
      @result = Export::Result.new(
        manifest: {schema: 1, channel: "live", sha256: "ab" * 32, file: "items.#{"ab" * 8}.json.gz", count: 0},
        items_gzip: "gz".b,
        file_name: "items.#{"ab" * 8}.json.gz"
      )
    end

    def requests(operation)
      @client.api_requests.select { |request| request[:operation_name] == operation }.map { |request| request[:params] }
    end

    test "uploads the items file before the manifest that names it, with their cache lifetimes" do
      @client.stub_responses(:get_object, "NoSuchKey")

      assert_equal :published, Publisher.new("live", client: @client).publish(@result)

      puts = requests(:put_object)
      assert_equal ["overlay/live/#{@result.file_name}", "overlay/live/manifest.json"], puts.map { |params| params[:key] }
      assert_equal Publisher::ITEMS_CACHE_CONTROL, puts.first[:cache_control]
      assert_equal Publisher::MANIFEST_CACHE_CONTROL, puts.last[:cache_control]
      assert_equal "public-read", puts.last[:acl]
      assert_equal @result.sha256, JSON.parse(puts.last[:body])["sha256"]
    end

    test "uploads nothing when the published manifest already names these bytes" do
      @client.stub_responses(:get_object, {body: JSON.generate(sha256: @result.sha256)})

      assert_equal :unchanged, Publisher.new("live", client: @client).publish(@result)
      assert_empty requests(:put_object)
    end

    test "deletes items files older than a day, but never the one just published" do
      @client.stub_responses(:get_object, "NoSuchKey")
      @client.stub_responses(:list_objects_v2, {contents: [
        {key: "overlay/live/items.0000000000000000.json.gz", last_modified: 2.days.ago},
        {key: "overlay/live/items.1111111111111111.json.gz", last_modified: 1.hour.ago},
        {key: "overlay/live/#{@result.file_name}", last_modified: 3.days.ago}
      ]})

      Publisher.new("live", client: @client).publish(@result)

      deleted = requests(:delete_objects).flat_map { |params| params[:delete][:objects].map { |object| object[:key] } }
      assert_equal ["overlay/live/items.0000000000000000.json.gz"], deleted
    end

    test "public URLs go through the storage CDN when there is one" do
      Rails.configuration.app.stubs(:storage_cdn_endpoint).returns("https://storage.test/")

      assert_equal "https://storage.test/overlay/ptu/manifest.json", Publisher.public_url("ptu", "manifest.json")
    end
  end
end
