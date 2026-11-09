# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CharacterBodiesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/character-bodies" do
    get("Character bodies") do
      operationId "characterBodies"
      tags "DressingRoom"
      produces "application/json"

      response(200, "successful") { schema ::V1::Schemas::DressingRoom::CharacterBodiesList }
      response(403, "feature disabled") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:dressing_room)
  end

  test "GET /character-bodies lists the bodies that have a holo, without signing in" do
    create(:character_body, :with_holo, key: "male", clips: [{"name" => "shop_pose_01", "static" => true, "looping" => false}])
    create(:character_body, key: "female")

    assert_api_response :get, 200 do
      assert_equal ["male"], parsed_body.pluck("key")
      assert_equal "plain.glb", parsed_body.first.dig("holo", "name")
      assert_nil parsed_body.first["holoTextured"]
      assert_nil parsed_body.first["animations"]
      assert_equal [{"name" => "shop_pose_01", "static" => true, "looping" => false}], parsed_body.first["clips"]
    end
  end

  test "GET /character-bodies serves a body's textured holo once it has one" do
    create(:character_body, :with_holo, :with_textured_holo, key: "male")

    assert_api_response :get, 200 do
      assert_equal "plain.glb", parsed_body.first.dig("holoTextured", "name")
    end
  end

  test "GET /character-bodies serves a body's skin tone and its face library once it has all of it" do
    create(:character_body, :with_holo, :with_face_library, key: "male", skin_tone: "#513428")
    create(:character_body, :with_holo, :with_face_library, key: "female", face_library: nil)

    assert_api_response :get, 200 do
      female, male = parsed_body
      assert_equal "#513428", male["skinTone"]
      assert_equal "male-6a268db0", male.dig("faceLibrary", "library")
      assert_equal %w[index.json library.bin normals.bin], %w[index positions normals].map { |file| male.dig("faceLibrary", file, "name") }
      assert_nil female["faceLibrary"]
      assert_nil female["skinTone"]
    end
  end

  test "GET /character-bodies serves each body's default character, resolved, once the export is in" do
    fixtures = Rails.root.join("test/fixtures/chf")
    catalog = CharacterAsset.create!(path: Chf::Context::CATALOG, etag: "catalog-1")
    catalog.file.attach(io: fixtures.join("catalog.json").open, filename: "catalog.json")
    body = create(:character_body, :with_holo, :with_face_library, key: "male", skin_tone: "#513428")
    body.face_index.attach(io: fixtures.join("male_faces_index.json").open, filename: "index.json")
    body.chf.attach(io: fixtures.join("masculinedefault.chf").open, filename: "default.chf")
    create(:character_body, :with_holo, key: "female")
    Chf::Context.reset!

    assert_api_response :get, 200 do
      female, male = parsed_body
      character = male["defaultCharacter"]
      assert_equal "male", character["body"]
      assert_includes character["hidden_parts"].keys, "hair_itemport"
      assert(character["meshes"].all? { |mesh| mesh.key?("materials_by_submaterial") })
      assert_nil female["defaultCharacter"]
      assert_equal "male-6a268db0", male.dig("faceLibrary", "library")
    end
  end

  test "GET /character-bodies serves the clip that holds a rifle lowered per armour weight" do
    create(:character_body, :with_holo, key: "male", hold_poses: [
      {"armor_weight" => nil, "clip" => "hold_rifle_lowered"},
      {"armor_weight" => "Heavy", "clip" => "hold_rifle_lowered_heavy"}
    ])

    assert_api_response :get, 200 do
      assert_equal [
        {"armorWeight" => nil, "clip" => "hold_rifle_lowered"},
        {"armorWeight" => "Heavy", "clip" => "hold_rifle_lowered_heavy"}
      ], parsed_body.first["holdPoses"]
    end
  end

  test "GET /character-bodies is forbidden while the feature is off" do
    Flipper.disable(:dressing_room)

    assert_api_response :get, 403
  end
end
