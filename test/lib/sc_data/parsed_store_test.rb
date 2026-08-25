# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module ScData
  class ParsedStoreTest < ActiveSupport::TestCase
    SETTINGS = {
      endpoint: "https://example.invalid",
      access_key_id: "key",
      secret_access_key: "secret",
      bucket: "fltyrd-sc"
    }.freeze

    setup do
      @root = Dir.mktmpdir
      @client = Aws::S3::Client.new(stub_responses: true)
    end

    teardown do
      FileUtils.remove_entry(@root)
    end

    # Settings and the client are both injected, so nothing here reaches the
    # credential store or the network.
    private def store(settings: SETTINGS)
      root = Pathname.new(@root)
      store = ::ScData::ParsedStore.new("live", client: @client, settings:)
      store.define_singleton_method(:local_root) { root }
      store
    end

    private def write_local(path, content)
      target = File.join(@root, path)
      FileUtils.mkdir_p(File.dirname(target))
      File.write(target, content)
      target
    end

    private def digest(content)
      Digest::MD5.hexdigest(content)
    end

    private def stub_listing(entries)
      @client.stub_responses(:list_objects_v2, {
        contents: entries.map { |key, content|
          {key: "parsed/live/#{key}", etag: %("#{digest(content)}")}
        }
      })
    end

    private def requests(operation)
      @client.api_requests
        .select { |request| request[:operation_name] == operation }
        .map { |request| request[:params] }
    end

    # --- Configuration ----------------------------------------------------

    test ".configured? is true only when every setting is present" do
      assert ::ScData::ParsedStore.configured?(SETTINGS)
      refute ::ScData::ParsedStore.configured?(SETTINGS.merge(bucket: nil))
      refute ::ScData::ParsedStore.configured?(SETTINGS.merge(access_key_id: ""))
    end

    # The message names what is missing: this surfaces on a loaders container
    # where nobody can inspect the credential store from the failure.
    test "raises NotConfigured naming the missing settings" do
      write_local("models/aurora.json", "a")

      error = assert_raises(::ScData::ParsedStore::NotConfigured) do
        store(settings: SETTINGS.merge(bucket: nil, endpoint: nil)).push
      end

      assert_match "endpoint", error.message
      assert_match "bucket", error.message
    end

    # --- Push -------------------------------------------------------------

    test "#push uploads only the files whose digest differs from the bucket" do
      write_local("models/aurora.json", "new")
      write_local("models/avenger.json", "same")
      stub_listing("models/avenger.json" => "same")

      result = store.push

      assert_equal ["parsed/live/models/aurora.json"], requests(:put_object).map { |r| r[:key] }
      assert_equal 1, result[:uploaded]
      assert_equal 1, result[:unchanged]
    end

    # A checkout without the tree is the normal state now that git no longer
    # carries it, so an accidental push from one must not read as "the parser
    # wrote nothing" and delete the bucket's copy.
    test "#push refuses an empty local tree rather than emptying the bucket" do
      stub_listing("models/aurora.json" => "a")

      assert_raises(::ScData::ParsedStore::MissingTree) { store.push }

      assert_empty requests(:delete_object)
      assert_empty requests(:list_objects_v2)
    end

    # The bucket has to mirror the tree, not accumulate it. A model file the
    # parser stopped writing must stop being served, or a pull would keep
    # handing the loader a ship that left the build.
    test "#push deletes what the bucket carries and the tree no longer does" do
      write_local("models/aurora.json", "a")
      stub_listing("models/aurora.json" => "a", "models/retired.json" => "b")

      result = store.push

      assert_equal ["parsed/live/models/retired.json"], requests(:delete_object).map { |r| r[:key] }
      assert_equal 1, result[:removed]
      assert_equal 0, result[:uploaded]
    end

    # --- Pull -------------------------------------------------------------

    test "#pull downloads what differs and leaves matching files alone" do
      write_local("models/avenger.json", "same")
      stub_listing("models/aurora.json" => "fetched", "models/avenger.json" => "same")
      @client.stub_responses(:get_object, {body: "fetched"})

      result = store.pull

      assert_equal "fetched", File.read(File.join(@root, "models/aurora.json"))
      assert_equal 1, result[:downloaded]
      assert_equal 1, result[:unchanged]
    end

    # `ModelsLoader#update_in_game_flag` reads a ship's in-game-ness off file
    # existence, so a leftover file from an earlier build would keep a retired
    # ship flying.
    test "#pull deletes local files the bucket no longer carries" do
      write_local("models/aurora.json", "a")
      write_local("models/retired.json", "b")
      stub_listing("models/aurora.json" => "a")

      result = store.pull

      refute File.exist?(File.join(@root, "models/retired.json"))
      assert File.exist?(File.join(@root, "models/aurora.json"))
      assert_equal 1, result[:removed]
    end

    # A directory is not an object, so nothing deletes it when its last file
    # goes. Left behind, the tree slowly fills with the shape of every build.
    test "#pull prunes directories it emptied" do
      write_local("icons/manufacturers/logos/talon.png", "x")
      stub_listing("models/aurora.json" => "a")
      @client.stub_responses(:get_object, {body: "a"})

      store.pull

      refute File.exist?(File.join(@root, "icons"))
    end

    # An empty listing means a tree that was never pushed, or a wrong prefix.
    # Treating it as "nothing to download" would mirror the emptiness onto disk
    # and hand the loader a tree that retires the whole catalogue.
    test "#pull refuses an empty bucket tree rather than emptying the local one" do
      write_local("models/aurora.json", "a")
      stub_listing({})

      assert_raises(::ScData::ParsedStore::MissingTree) { store.pull }

      assert File.exist?(File.join(@root, "models/aurora.json"))
    end

    # --- Version ----------------------------------------------------------

    test "#remote_version reads the version the parser stamped on the tree" do
      @client.stub_responses(:get_object, {body: {version: "4.9.0-live.1", environment: "live"}.to_json})

      assert_equal "4.9.0-live.1", store.remote_version
    end

    test "#remote_version is nil when the tree carries no version.json" do
      @client.stub_responses(:get_object, "NoSuchKey")

      assert_nil store.remote_version
    end

    # Pointer and payload live apart and can disagree -- a half-finished push,
    # or a config bumped ahead of the upload. Loading the wrong tree would
    # stamp every row with a version it does not describe.
    test "#verify_remote_version! raises when the tree is a different build" do
      @client.stub_responses(:get_object, {body: {version: "4.9.0-live.1"}.to_json})

      error = assert_raises(::ScData::ParsedStore::VersionMismatch) do
        store.verify_remote_version!("4.9.1-live.2")
      end

      assert_match "4.9.0-live.1", error.message
      assert_match "4.9.1-live.2", error.message
    end

    test "#verify_remote_version! passes when the tree is the expected build" do
      @client.stub_responses(:get_object, {body: {version: "4.9.0-live.1"}.to_json})

      assert store.verify_remote_version!("4.9.0-live.1")
    end
  end
end
