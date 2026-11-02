# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module ScData
  class CharacterBodiesImportJobTest < ActiveJob::TestCase
    SETTINGS = {
      endpoint: "https://example.invalid",
      access_key_id: "key",
      secret_access_key: "secret",
      bucket: "fltyrd-sc"
    }.freeze

    BODY = Rails.root.join("test/fixtures/holo/plain.glb").binread
    ANIMATIONS = Rails.root.join("test/fixtures/holo/plain.gltf").binread

    setup do
      @objects = {}
      @index = {}
      @client = Aws::S3::Client.new(stub_responses: true)
      @client.stub_responses(:get_object, ->(context) {
        body = @objects[context.params[:key].delete_prefix("characters/")]
        body ? {body:} : "NoSuchKey"
      })

      store = ::ScData::CharacterStore.new(client: @client, settings: SETTINGS)
      ::ScData::CharacterStore.stubs(:configured?).returns(true)
      ::ScData::CharacterStore.stubs(:new).returns(store)
    end

    private def publish(key, files, digest: "listing-1")
      @index[key] = {files: digest, updatedAt: "2026-11-02T00:00:00Z"}
      @objects["index.json"] = {characters: @index}.to_json
      @objects["#{key}/files.json"] = {
        files: files.to_h { |name, content| [name, {md5: Digest::MD5.hexdigest(content), size: content.bytesize}] }
      }.to_json
      files.each { |name, content| @objects["#{key}/#{name}"] = content }
    end

    private def fetched
      @client.api_requests
        .select { |request| request[:operation_name] == :get_object }
        .map { |request| File.basename(request[:params][:key]) }
    end

    test "creates a body per listed folder and attaches its rest-pose holo" do
      publish("male", {"body.glb" => BODY, "animations.glb" => ANIMATIONS})

      ::ScData::CharacterBodiesImportJob.new.perform

      body = CharacterBody.find_by!(key: "male")
      assert body.holo.attached?
      assert_equal "body.glb", body.holo.filename.to_s
      assert_equal "listing-1", body.views_digest
      assert_not_includes fetched, "animations.glb"
    end

    test "skips a body whose listing has not changed" do
      publish("male", {"body.glb" => BODY})
      ::ScData::CharacterBodiesImportJob.new.perform
      @client.api_requests.clear

      ::ScData::CharacterBodiesImportJob.new.perform

      assert_equal ["index.json"], fetched
    end

    test "does nothing without a configured store" do
      ::ScData::CharacterStore.stubs(:configured?).returns(false)

      ::ScData::CharacterBodiesImportJob.new.perform

      assert_equal 0, CharacterBody.count
    end
  end
end
