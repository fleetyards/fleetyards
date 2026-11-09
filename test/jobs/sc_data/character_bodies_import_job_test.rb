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

    test "lights a body in the studio when the lighting file has one: its environment and the studio's key light" do
      publish("male", {"body.glb" => BODY})
      @objects["lighting.json"] = {
        environment: {url: "characters/environment/studio.hdr", intensity: 1.0, toneMappingExposure: 0.6156},
        rigs: {
          review_male: {lights: [{type: "point", position: [0, 2, 0], color: [1, 1, 1], intensity: 5}]},
          studio: {lights: [{type: "spot", position: [1.6, 2.6, -2.4], target: [0, 1.3, 0], color: [1, 1, 1], intensity: 190, decay: 2, castShadow: true, three: {angle: 0.62, penumbra: 0.6}}]}
        }
      }.to_json
      @objects["index.json"] = JSON.parse(@objects["index.json"]).merge("lighting" => {"file" => "characters/lighting.json"}).to_json

      ::ScData::CharacterBodiesImportJob.new.perform

      body = CharacterBody.find_by!(key: "male")
      assert_equal({"map" => "characters/environment/studio.hdr", "intensity" => 1.0, "exposure" => 0.6156}, body.environment)
      key = body.lighting.sole
      assert_equal "spot", key["type"]
      assert key["cast_shadow"]
      assert_in_delta(-0.5057, key["direction"][0], 0.001)
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

    test "takes in a listed file the job only learned to read after the listing last changed" do
      publish("male", {"body.glb" => BODY, "body_textured.glb" => BODY})
      known = ::ScData::CharacterBodiesImportJob::FIELDS.except("body_textured.glb")
      stub_const(::ScData::CharacterBodiesImportJob, :FIELDS, known) do
        ::ScData::CharacterBodiesImportJob.new.perform
      end
      assert_not CharacterBody.find_by!(key: "male").holo_textured.attached?
      @client.api_requests.clear

      ::ScData::CharacterBodiesImportJob.new.perform

      assert_equal ["index.json", "body_textured.glb"], fetched
      assert_equal "body_textured.glb", CharacterBody.find_by!(key: "male").holo_textured.filename.to_s
    end

    FACES = {"index.json" => "{}", "library.bin" => "positions", "normals.bin" => "normals"}.freeze

    private def publish_faces(key, files, library: "#{key}-6a268db0")
      @index[key][:faces] = {
        path: "characters/#{key}/faces/",
        library:,
        files: files.merge("README.md" => "spec").to_h { |name, content| [name, {md5: Digest::MD5.hexdigest(content), size: content.bytesize}] }
      }
      @objects["index.json"] = {bodies: @index}.to_json
      files.each { |name, content| @objects["#{key}/faces/#{name}"] = content }
    end

    test "attaches a body's face library and its skin tone, and names the build once all of it is there" do
      publish("male", {"body.glb" => BODY})
      @index["male"][:skin] = {tone: "#513428", note: "baked at"}
      publish_faces("male", FACES)

      ::ScData::CharacterBodiesImportJob.new.perform

      body = CharacterBody.find_by!(key: "male")
      assert_equal "male-6a268db0", body.face_library
      assert_equal "#513428", body.skin_tone
      assert_equal "positions", body.face_positions.download
      assert_equal "normals", body.face_normals.download
      assert_equal "index.json", body.face_index.filename.to_s
      assert_not_includes fetched, "README.md"
    end

    test "names no build while a new one is half imported, and the new one once it is whole" do
      publish("male", {"body.glb" => BODY})
      publish_faces("male", FACES)
      ::ScData::CharacterBodiesImportJob.new.perform

      publish_faces("male", FACES.merge("library.bin" => "new positions"), library: "male-7b000000")
      @objects.delete("male/faces/library.bin")
      ::ScData::CharacterBodiesImportJob.new.perform

      body = CharacterBody.find_by!(key: "male")
      assert_nil body.face_library
      assert_not body.face_library?

      @objects["male/faces/library.bin"] = "new positions"
      ::ScData::CharacterBodiesImportJob.new.perform

      assert_equal "male-7b000000", body.reload.face_library
      assert_equal "new positions", body.face_positions.download
    end

    test "skips a face library whose listing has not changed" do
      publish("male", {"body.glb" => BODY})
      publish_faces("male", FACES)
      ::ScData::CharacterBodiesImportJob.new.perform
      @client.api_requests.clear

      ::ScData::CharacterBodiesImportJob.new.perform

      assert_equal ["index.json"], fetched
    end

    test "attaches a body's default character file and resolves it afresh when it changes" do
      publish("male", {"body.glb" => BODY})
      chf = "BB default"
      @index["male"][:defaultCharacter] = {
        chf: "characters/male/default/default.chf",
        files: {"default.chf" => {md5: Digest::MD5.hexdigest(chf), size: chf.bytesize}, "default_character.glb" => {md5: "x", size: 1}}
      }
      @objects["index.json"] = {bodies: @index}.to_json
      @objects["male/default/default.chf"] = chf

      ::ScData::CharacterBodiesImportJob.new.perform

      body = CharacterBody.find_by!(key: "male")
      assert_equal chf, body.chf.download
      assert_not_includes fetched, "default_character.glb"

      body.update_columns(resolved: {"body" => "male"}, resolved_digest: "old")
      changed = "BB changed"
      @index["male"][:defaultCharacter][:files]["default.chf"] = {md5: Digest::MD5.hexdigest(changed), size: changed.bytesize}
      @objects["index.json"] = {bodies: @index}.to_json
      @objects["male/default/default.chf"] = changed
      ::ScData::CharacterBodiesImportJob.new.perform

      assert_equal changed, body.reload.chf.download
      assert_nil body.resolved
    end

    test "drops a skin tone that is not a colour" do
      publish("male", {"body.glb" => BODY})
      @index["male"][:skin] = {tone: "dark"}
      @objects["index.json"] = {bodies: @index}.to_json

      ::ScData::CharacterBodiesImportJob.new.perform

      assert_nil CharacterBody.find_by!(key: "male").skin_tone
    end

    test "does nothing without a configured store" do
      ::ScData::CharacterStore.stubs(:configured?).returns(false)

      ::ScData::CharacterBodiesImportJob.new.perform

      assert_equal 0, CharacterBody.count
    end
  end
end
