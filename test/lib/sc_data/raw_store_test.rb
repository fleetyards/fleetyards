# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module ScData
  class RawStoreTest < ActiveSupport::TestCase
    SETTINGS = {
      endpoint: "https://example.invalid",
      access_key_id: "key",
      secret_access_key: "secret",
      bucket: "fltyrd-sc"
    }.freeze

    VERSION = "4.10.1-ptu.12578875"

    setup do
      @root = Dir.mktmpdir
      @client = Aws::S3::Client.new(stub_responses: true)
    end

    teardown do
      FileUtils.remove_entry(@root)
    end

    # Settings and the client are both injected, so nothing here reaches the
    # credential store or the network.
    private def store(version: VERSION)
      root = Pathname.new(@root)
      store = ::ScData::RawStore.new(version, client: @client, settings: SETTINGS)
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

    # Keyed the way the exporter uploads: the version folder sits at the root of
    # the bucket, not under a prefix of ours.
    private def stub_listing(entries)
      @client.stub_responses(:list_objects_v2, {
        contents: entries.map { |key, object|
          etag, size = object.is_a?(Array) ? object : [digest(object), object.bytesize]
          {key: "#{VERSION}/#{key}", etag: %("#{etag}"), size:}
        }
      })
    end

    private def requests(operation)
      @client.api_requests
        .select { |request| request[:operation_name] == operation }
        .map { |request| request[:params] }
    end

    # --- Versions ---------------------------------------------------------

    test ".versions lists the exports in the bucket, oldest build first" do
      @client.stub_responses(:list_objects_v2, {
        common_prefixes: [
          {prefix: "4.10.1-ptu.12578875/"},
          {prefix: "parsed/"},
          {prefix: "4.9.0-live.12344265/"},
          {prefix: "4.10.0-live.12519617/"}
        ]
      })

      assert_equal ["4.9.0-live.12344265", "4.10.0-live.12519617", "4.10.1-ptu.12578875"],
        ::ScData::RawStore.versions(client: @client, settings: SETTINGS)
    end

    # Ordered by build id rather than release, so a ptu export on the same
    # release as live still resolves to the newer of the two.
    test ".latest picks the newest export published to an environment" do
      @client.stub_responses(:list_objects_v2, {
        common_prefixes: [
          {prefix: "4.10.0-live.12519617/"},
          {prefix: "4.10.1-ptu.12578875/"},
          {prefix: "4.10.0-ptu.12480000/"}
        ]
      })

      assert_equal "4.10.1-ptu.12578875", ::ScData::RawStore.latest("ptu", client: @client, settings: SETTINGS)
      assert_equal "4.10.0-live.12519617", ::ScData::RawStore.latest("live", client: @client, settings: SETTINGS)
    end

    test ".latest is nil for an environment the bucket carries no export for" do
      @client.stub_responses(:list_objects_v2, {common_prefixes: [{prefix: "4.10.0-live.12519617/"}]})

      assert_nil ::ScData::RawStore.latest("ptu", client: @client, settings: SETTINGS)
    end

    # --- Pull -------------------------------------------------------------

    test "#pull downloads what differs and leaves matching files alone" do
      write_local("Data/Libs/avenger.xml", "same")
      stub_listing("Data/Libs/aurora.xml" => "fetched", "Data/Libs/avenger.xml" => "same")
      @client.stub_responses(:get_object, {body: "fetched"})

      result = store.pull

      assert_equal "fetched", File.read(File.join(@root, "Data/Libs/aurora.xml"))
      assert_equal ["#{VERSION}/Data/Libs/aurora.xml"], requests(:get_object).map { |r| r[:key] }
      assert_equal 1, result[:downloaded]
      assert_equal 1, result[:unchanged]
    end

    # A multipart ETag is a digest of the part digests with the count appended,
    # so no local file can ever match it. `Data/Game2.dcb` is 331 MB and comes
    # back as `...-40`: comparing digests there re-downloads the largest files
    # in the export on every run.
    test "#pull compares a multipart object by size rather than by digest" do
      write_local("Data/Game2.dcb", "a" * 64)
      stub_listing("Data/Game2.dcb" => ["d41d8cd98f00b204e9800998ecf8427e-40", 64])

      result = store.pull

      assert_empty requests(:get_object)
      assert_equal 0, result[:downloaded]
      assert_equal 1, result[:unchanged]
    end

    test "#pull fetches a multipart object again when the byte count differs" do
      write_local("Data/Game2.dcb", "a" * 32)
      stub_listing("Data/Game2.dcb" => ["d41d8cd98f00b204e9800998ecf8427e-40", 64])
      @client.stub_responses(:get_object, {body: "b" * 64})

      assert_equal 1, store.pull[:downloaded]
    end

    # An export is immutable and nothing local is authoritative, so there is
    # nothing to mirror away -- unlike the parsed tree, whose absences say a
    # ship left the build.
    test "#pull leaves local files the export does not carry" do
      write_local("Data/Libs/aurora.xml", "a")
      write_local("scratch.txt", "mine")
      stub_listing("Data/Libs/aurora.xml" => "a")

      result = store.pull

      assert File.exist?(File.join(@root, "scratch.txt"))
      assert_empty requests(:delete_object)
      assert_equal 0, result[:downloaded]
    end

    # An empty listing is a version that was never uploaded, or a typo in one.
    # Parsing whatever is on disk would stamp the rows with a build they do not
    # describe.
    test "#pull refuses an empty export rather than reporting nothing to do" do
      stub_listing({})

      assert_raises(::ScData::RawStore::MissingTree) { store.pull }
    end

    # A blank prefix lists -- and would start downloading -- the whole bucket.
    test "#pull without a version refuses before listing anything" do
      assert_raises(ArgumentError) { store(version: nil).pull }

      assert_empty requests(:list_objects_v2)
    end

    test "raises NotConfigured naming the missing settings" do
      raw = ::ScData::RawStore.new(VERSION, client: @client, settings: SETTINGS.merge(bucket: nil))

      error = assert_raises(::ScData::RawStore::NotConfigured) { raw.pull }

      assert_match "bucket", error.message
    end
  end
end
