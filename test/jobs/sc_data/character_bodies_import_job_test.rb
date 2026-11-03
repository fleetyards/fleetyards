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

    CLIPS = [
      {"name" => "shop_pose_01", "static" => true, "looping" => false, "frames" => 1, "fps" => 30.0, "source" => "poses.dba#01"},
      {"name" => "idle_stand", "static" => false, "looping" => true, "frames" => 131, "fps" => 30.0, "source" => "idle.dba"}
    ].freeze

    private def publish(key, files, clips: CLIPS)
      @index[key] = {
        body: "characters/#{key}/body.glb",
        animations: "characters/#{key}/animations.glb",
        files: files.to_h { |name, content| [name, {md5: Digest::MD5.hexdigest(content), size: content.bytesize}] },
        clips:,
        weaponInHand: {
          bones: {right: "RightWeaponBone", left: "LeftWeaponBone"},
          helper: {position: [0, 0, 0], rotation: [-0.707107, 0, 0, 0.707107]},
          note: "the item origin goes on the bone"
        }
      }
      @objects["index.json"] = {updatedAt: "2026-11-02T00:00:00Z", bodies: @index}.to_json
      files.each { |name, content| @objects["#{key}/#{name}"] = content }
    end

    private def fetched
      @client.api_requests
        .select { |request| request[:operation_name] == :get_object }
        .map { |request| File.basename(request[:params][:key]) }
    end

    test "creates a body per listed body with its rest pose, its clips and what each clip is" do
      publish("male", {"body.glb" => BODY, "body_textured.glb" => BODY, "animations.glb" => ANIMATIONS})

      ::ScData::CharacterBodiesImportJob.new.perform

      body = CharacterBody.find_by!(key: "male")
      assert_equal "body.glb", body.holo.filename.to_s
      assert_equal "body_textured.glb", body.holo_textured.filename.to_s
      assert_equal "animations.glb", body.animations.filename.to_s
      assert_equal "RightWeaponBone", body.weapon_in_hand.dig("bones", "right")
      assert_equal [-0.707107, 0, 0, 0.707107], body.weapon_in_hand.dig("helper", "rotation")
      assert_nil body.weapon_in_hand["note"]
      assert_equal [
        {"name" => "shop_pose_01", "static" => true, "looping" => false},
        {"name" => "idle_stand", "static" => false, "looping" => true}
      ], body.clips
    end

    test "keeps a body's weapon hand only when the export states it whole" do
      publish("male", {"body.glb" => BODY})
      @index["male"][:weaponInHand] = {bones: {right: "RightWeaponBone"}, helper: {position: [0, 0, 0]}}
      @objects["index.json"] = {bodies: @index}.to_json

      ::ScData::CharacterBodiesImportJob.new.perform

      assert_nil CharacterBody.find_by!(key: "male").weapon_in_hand
    end

    test "keeps a body's lights when the lighting file cannot be read, and drops a light's non-numeric extras" do
      publish("male", {"body.glb" => BODY})
      @objects["lighting.json"] = {rigs: {review_male: {lights: [
        {type: "spot", position: [0, 3, 1], direction: [0, -1, 0], color: [0.1, 0.3, 0.5], intensity: 50, range: "far", three: {angle: 0.5, penumbra: 0.2}}
      ]}}}.to_json
      index = JSON.parse(@objects["index.json"]).merge("lighting" => {"file" => "characters/lighting.json"})
      @objects["index.json"] = index.to_json

      ::ScData::CharacterBodiesImportJob.new.perform
      light = CharacterBody.find_by!(key: "male").lighting.sole
      assert_nil light["range"]
      assert_in_delta 0.5, light["angle"]

      @objects.delete("lighting.json")
      ::ScData::CharacterBodiesImportJob.new.perform

      assert_equal 1, CharacterBody.find_by!(key: "male").lighting.size
    end

    test "takes in a changed clip list without fetching the files again" do
      publish("male", {"body.glb" => BODY})
      ::ScData::CharacterBodiesImportJob.new.perform
      @client.api_requests.clear

      publish("male", {"body.glb" => BODY}, clips: CLIPS.first(1))
      ::ScData::CharacterBodiesImportJob.new.perform

      assert_equal ["index.json"], fetched
      assert_equal ["shop_pose_01"], CharacterBody.find_by!(key: "male").clips.pluck("name")
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
