# frozen_string_literal: true

require "test_helper"
require "aws-sdk-s3"

module ScData
  class CharacterAssetsImportJobTest < ActiveJob::TestCase
    SETTINGS = {
      endpoint: "https://example.invalid",
      access_key_id: "key",
      secret_access_key: "secret",
      bucket: "fltyrd-sc"
    }.freeze

    setup do
      @objects = {}
      @etags = {}
      @client = Aws::S3::Client.new(stub_responses: true)
      @client.stub_responses(:list_objects_v2, ->(_context) {
        {contents: @objects.map { |path, body| {key: "characters/#{path}", etag: %("#{@etags.fetch(path) { Digest::MD5.hexdigest(body) }}"), size: body.bytesize} }}
      })
      @client.stub_responses(:get_object, ->(context) {
        body = @objects[context.params[:key].delete_prefix("characters/")]
        body ? {body:} : "NoSuchKey"
      })

      store = ::ScData::CharacterStore.new(client: @client, settings: SETTINGS)
      ::ScData::CharacterStore.stubs(:configured?).returns(true)
      ::ScData::CharacterStore.stubs(:new).returns(store)
    end

    private def fetched
      @client.api_requests
        .select { |request| request[:operation_name] == :get_object }
        .map { |request| request[:params][:key] }
    end

    test "attaches every file a character can name, and nothing of the specs, scripts or tests beside them" do
      @objects.merge!(
        "chf/catalog.json" => "{}",
        "chf/textures/heads/blemish/blemish_mask_mask.webp" => "mask",
        "male/chf/index.json" => "{}",
        "male/chf/geometry/m_hair_02.glb" => "hair",
        "female/chf/skin/female01_t2_head_material_base.webp" => "skin",
        "chf/README.md" => "spec",
        "chf/reference_character.py" => "script",
        "chf/tests/Macken.chf" => "chf",
        "male/faces/library.bin" => "library",
        "male/body.glb" => "body"
      )

      ::ScData::CharacterAssetsImportJob.new.perform

      assert_equal %w[
        characters/chf/catalog.json
        characters/chf/textures/heads/blemish/blemish_mask_mask.webp
        characters/female/chf/skin/female01_t2_head_material_base.webp
        characters/male/chf/geometry/m_hair_02.glb
        characters/male/chf/index.json
      ], CharacterAsset.order(:path).pluck(:path)
      asset = CharacterAsset.find_by!(path: "characters/male/chf/geometry/m_hair_02.glb")
      assert_equal "hair", asset.file.download
      assert_equal "m_hair_02.glb", asset.file.filename.to_s
      assert_equal Digest::MD5.hexdigest("hair"), asset.etag
      assert_equal 4, asset.size
    end

    test "fetches only what changed since the last run" do
      @objects["chf/catalog.json"] = "{}"
      @objects["male/chf/geometry/m_hair_02.glb"] = "hair"
      ::ScData::CharacterAssetsImportJob.new.perform
      @client.api_requests.clear

      @objects["male/chf/geometry/m_hair_02.glb"] = "longer hair"
      ::ScData::CharacterAssetsImportJob.new.perform

      assert_equal ["characters/male/chf/geometry/m_hair_02.glb"], fetched
      assert_equal "longer hair", CharacterAsset.find_by!(path: "characters/male/chf/geometry/m_hair_02.glb").file.download
    end

    test "skips a file that does not match its listing and takes it next run" do
      @objects["male/chf/geometry/m_hair_02.glb"] = "hair"
      @etags["male/chf/geometry/m_hair_02.glb"] = Digest::MD5.hexdigest("other")

      ::ScData::CharacterAssetsImportJob.new.perform
      assert_not CharacterAsset.exists?(path: "characters/male/chf/geometry/m_hair_02.glb")

      @etags.clear
      ::ScData::CharacterAssetsImportJob.new.perform

      assert CharacterAsset.find_by!(path: "characters/male/chf/geometry/m_hair_02.glb").file.attached?
    end

    test "checks only the size of a multipart upload, whose ETag is no MD5" do
      @objects["male/chf/geometry/m_hair_02.glb"] = "hair"
      @etags["male/chf/geometry/m_hair_02.glb"] = "#{Digest::MD5.hexdigest("parts")}-2"

      ::ScData::CharacterAssetsImportJob.new.perform

      assert_equal "hair", CharacterAsset.find_by!(path: "characters/male/chf/geometry/m_hair_02.glb").file.download
    end

    test "does nothing without a configured store" do
      ::ScData::CharacterStore.stubs(:configured?).returns(false)
      @objects["chf/catalog.json"] = "{}"

      ::ScData::CharacterAssetsImportJob.new.perform

      assert_equal 0, CharacterAsset.count
    end
  end
end
