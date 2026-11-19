# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module Maintenance
  class RetypeGltfBlobsTaskTest < ActiveSupport::TestCase
    S3Store = Struct.new(:name, :bucket, :upload_options)
    # Active Storage's own metadata update is a no-op on S3: the reason the task
    # copies the objects.
    MirrorStore = Struct.new(:primary, :mirrors) do
      def update_metadata(*) = nil
    end

    setup do
      @holo = blob("flight_textured.glb", "application/octet-stream")
      @json_holo = blob("flight_holo.gltf", "")
    end

    test "dry_run is on unless it is turned off" do
      assert_predicate ::Maintenance::RetypeGltfBlobsTask.new, :dry_run
    end

    test "#collection holds the untyped glTF blobs only" do
      typed = blob("landed_textured.glb", "model/gltf-binary")
      image = blob("flight_angled.webp", "application/octet-stream")

      collection = ::Maintenance::RetypeGltfBlobsTask.new.collection

      assert_includes collection, @holo
      assert_includes collection, @json_holo
      assert_not_includes collection, typed
      assert_not_includes collection, image
    end

    test "#collection narrows to the given blob ids" do
      task = ::Maintenance::RetypeGltfBlobsTask.new
      task.blob_ids = " #{@holo.id} "

      assert_equal [@holo], task.collection.to_a
    end

    test "#process reports and changes nothing on a dry run" do
      output = capture_io { ::Maintenance::RetypeGltfBlobsTask.new.process(@holo) }.first

      assert_includes output, "would retype Blob##{@holo.id} flight_textured.glb (#{@holo.key}) to model/gltf-binary"
      assert_equal "application/octet-stream", @holo.reload.content_type
    end

    test "#process restamps every store's object, keeping its headers, then the blob" do
      clients = [stub_client, stub_client]
      stores = clients.each_with_index.map { |client, index| s3_store("store#{index}", client) }
      task = real_run

      @holo.stubs(:service).returns(MirrorStore.new(stores.first, stores.drop(1)))
      capture_io { task.process(@holo) }

      clients.each do |client|
        copy = client.api_requests.find { |request| request[:operation_name] == :copy_object }[:params]

        assert_equal "REPLACE", copy[:metadata_directive]
        assert_equal "model/gltf-binary", copy[:content_type]
        assert_equal "inline", copy[:content_disposition]
        assert_equal "max-age=1", copy[:cache_control]
        assert_equal({"identified" => "true"}, copy[:metadata])
        assert_equal "public-read", copy[:acl]
        assert_equal "bucket/#{@holo.key}", copy[:copy_source]
      end
      assert_equal "model/gltf-binary", @holo.reload.content_type
    end

    test "#process leaves the blob untyped when a store does not take the new type" do
      store = s3_store("bunny", stub_client(served: "application/octet-stream"))

      @holo.stubs(:service).returns(store)
      error = assert_raises(RuntimeError) { real_run.process(@holo) }

      assert_includes error.message, "bunny: #{@holo.key} is still served as \"application/octet-stream\""
      assert_equal "application/octet-stream", @holo.reload.content_type
    end

    test "#process skips a store the object never reached" do
      present = stub_client
      missing = stub_client(missing: true)
      @holo.stubs(:service).returns(MirrorStore.new(s3_store("bunny", missing), [s3_store("hetzner", present)]))

      output = capture_io { real_run.process(@holo) }.first

      assert_includes output, "bunny: #{@holo.key} is not there, skipped"
      assert_includes output, "hetzner: #{@holo.key} retyped"
      assert_empty(missing.api_requests.select { |request| request[:operation_name] == :copy_object })
      assert_equal "model/gltf-binary", @holo.reload.content_type
    end

    test "#process retypes a blob on a store without objects of its own" do
      capture_io { real_run.process(@json_holo) }

      assert_equal "model/gltf+json", @json_holo.reload.content_type
    end

    private def blob(filename, content_type)
      ActiveStorage::Blob.create!(
        key: SecureRandom.base36(28), filename:, content_type:, byte_size: 4, checksum: "x", service_name: "test"
      )
    end

    private def real_run
      ::Maintenance::RetypeGltfBlobsTask.new.tap { |task| task.dry_run = false }
    end

    # Answers the load with the object as uploaded and every later head with
    # what the store serves after the copy.
    private def stub_client(served: "model/gltf-binary", missing: false)
      uploaded = {content_type: "application/octet-stream", content_disposition: "inline",
                  cache_control: "max-age=1", metadata: {"identified" => "true"}}
      heads = [uploaded, {content_type: served}]
      Aws::S3::Client.new(stub_responses: true).tap do |client|
        client.stub_responses(:head_object, if missing
          "NotFound"
        else
          ->(_context) { (heads.size > 1) ? heads.shift : heads.first }
        end)
        client.stub_responses(:copy_object, {copy_object_result: {etag: "\"etag\""}})
      end
    end

    private def s3_store(name, client)
      S3Store.new(name, Aws::S3::Bucket.new("bucket", client:), {acl: "public-read"})
    end
  end
end
