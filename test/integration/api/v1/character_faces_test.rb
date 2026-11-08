# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CharacterFacesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  READ_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:read"]},
    {OpenId: ["hangar", "hangar:read"]}
  ].freeze

  WRITE_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  api_path "/character-faces" do
    get("Character faces") do
      operationId "characterFaces"
      tags "DressingRoom"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::DressingRoom::CharacterFacesList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "feature disabled") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Upload Character face") do
      operationId "createCharacterFace"
      tags "DressingRoom"
      consumes "multipart/form-data"
      produces "application/json"
      security WRITE_SECURITY

      # Not required: by the time the request validation middleware reads the
      # body, Rack has consumed the multipart stream, so it would refuse every
      # upload. The controller requires the file instead.
      request_body required: false, content: {"multipart/form-data" => {schema: ::V1::Schemas::Inputs::CharacterFaceCreateInput}}

      response(201, "successful") { schema ::V1::Schemas::DressingRoom::CharacterFace }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/character-faces/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Rename Character face") do
      operationId "updateCharacterFace"
      tags "DressingRoom"
      consumes "application/json"
      produces "application/json"
      security WRITE_SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::CharacterFaceUpdateInput

      response(200, "successful") { schema ::V1::Schemas::DressingRoom::CharacterFace }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Destroy Character face") do
      operationId "destroyCharacterFace"
      tags "DressingRoom"
      produces "application/json"
      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::SuccessResponse }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/character-faces/shared/{token}" do
    parameter name: "token", in: :path, schema: {type: :string}, required: true

    get("Shared Character face") do
      operationId "sharedCharacterFace"
      tags "DressingRoom"
      produces "application/json"

      response(200, "successful") { schema ::V1::Schemas::DressingRoom::SharedCharacterFace }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  FIXTURES = Rails.root.join("test/fixtures/chf")
  SKIN_TONES = {"male" => "#513428", "female" => "#cca089"}.freeze

  setup do
    Flipper.enable(:dressing_room)
    @user = create(:user)
  end

  private def upload(name) = Rack::Test::UploadedFile.new(FIXTURES.join("#{name}.chf"), "application/octet-stream")

  # The imported customizer export the resolution needs: the catalogue as an
  # asset and a face library on the body.
  private def import_customizer
    asset = CharacterAsset.create!(path: Chf::Context::CATALOG, etag: "catalog-1")
    asset.file.attach(io: FIXTURES.join("catalog.json").open, filename: "catalog.json")
    %w[male female].each do |key|
      body = create(:character_body, :with_holo, key:, skin_tone: SKIN_TONES[key], face_library: "#{key}-lib")
      body.face_index.attach(io: FIXTURES.join("#{key}_faces_index.json").open, filename: "index.json")
      body.face_positions.attach(io: StringIO.new("0"), filename: "library.bin")
      body.face_normals.attach(io: StringIO.new("0"), filename: "normals.bin")
    end
    Chf::Context.reset!
  end

  test "POST /character-faces keeps the uploaded file as it was, with what it says about itself" do
    sign_in @user
    ScData::Source.stubs(:find).with("live").returns(ScData::Source.new(environment: "live", version: "4.10.197"))

    assert_api_response :post, 201, api_path: "/character-faces", body: {file: upload("Macken")} do
      assert_equal "Macken", parsed_body["name"]
      assert_equal "male", parsed_body["body"]
      assert_equal "68c929ba", parsed_body["dnaStamp"]
      assert_equal "f6676cdd", parsed_body["genderHash"]
      assert_equal 7, parsed_body["formatVersion"]
      assert_equal "4.10.197", parsed_body["gameVersion"]
      assert_equal 24, parsed_body["token"].size
    end

    assert_equal FIXTURES.join("Macken.chf").binread, @user.character_faces.sole.chf.download
  end

  test "POST /character-faces refuses a file that is not a character file" do
    sign_in @user
    file = Rack::Test::UploadedFile.new(StringIO.new("not a character"), "application/octet-stream", original_filename: "x.chf")

    assert_api_response :post, 400, api_path: "/character-faces", body: {file:} do
      assert_equal ["file"], parsed_body["errors"].pluck("attribute")
      assert_equal ["invalid"], parsed_body.dig("errors", 0, "messages").pluck("code")
    end

    assert_equal 0, CharacterFace.count
  end

  test "POST /character-faces refuses a character for the other body than the one being dressed" do
    sign_in @user

    assert_api_response :post, 400, api_path: "/character-faces", body: {file: upload("meg"), body: "male"} do
      assert_equal ["other_body"], parsed_body.dig("errors", 0, "messages").pluck("code")
      assert_equal ["File is a character for the other body"], parsed_body.dig("errors", 0, "messages").pluck("message")
    end
  end

  test "POST /character-faces takes the name it is given over the file's" do
    sign_in @user

    assert_api_response :post, 201, api_path: "/character-faces", body: {file: upload("meg"), name: "Recon", body: "female"} do
      assert_equal "Recon", parsed_body["name"]
      assert_equal "female", parsed_body["body"]
    end
  end

  test "POST /character-faces names a second upload of the same file apart, and keeps a long file name short" do
    sign_in @user
    create(:character_face, user: @user, name: "Macken")

    assert_api_response :post, 201, api_path: "/character-faces", body: {file: upload("Macken")} do
      assert_equal "Macken (2)", parsed_body["name"]
      assert_equal "Macken (2).chf", parsed_body.dig("file", "name")
    end

    long = Rack::Test::UploadedFile.new(FIXTURES.join("Macken.chf"), "application/octet-stream", original_filename: "#{"x" * 150}.chf")
    assert_api_response :post, 201, api_path: "/character-faces", body: {file: long} do
      assert_equal "x" * 90, parsed_body["name"]
    end
  end

  test "POST /character-faces refuses a file field that is not a file" do
    sign_in @user

    post "/api/v1/character-faces", params: {file: "abc"}, headers: {"Accept" => "application/json"}

    assert_response :bad_request
    assert_equal ["invalid"], response.parsed_body.dig("errors", 0, "messages").pluck("code")
  end

  test "POST /character-faces without a file is a bad request" do
    sign_in @user

    post "/api/v1/character-faces", params: {name: "Nothing"}, headers: {"Accept" => "application/json"}

    assert_response :bad_request
    assert_equal 0, CharacterFace.count
  end

  test "GET /character-faces lists the user's characters only" do
    create(:character_face, user: @user, name: "Mine")
    create(:character_face, name: "Someone else's")
    sign_in @user

    assert_api_response :get, 200, api_path: "/character-faces" do
      assert_equal ["Mine"], parsed_body.pluck("name")
      assert_equal "application/octet-stream", parsed_body.first.dig("file", "contentType")
    end
  end

  test "GET /character-faces returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/character-faces"
  end

  test "PUT /character-faces/{id} renames a character, and not someone else's" do
    face = create(:character_face, user: @user, name: "Old")
    other = create(:character_face, name: "Theirs")
    sign_in @user

    assert_api_response :put, 200, api_path: "/character-faces/{id}", path_params: {id: face.id}, body: {name: "New"} do
      assert_equal "New", parsed_body["name"]
    end
    assert_api_response :put, 404, api_path: "/character-faces/{id}", path_params: {id: other.id}, body: {name: "Mine now"}
  end

  test "DELETE /character-faces/{id} deletes a character and takes it off the outfits wearing it" do
    face = create(:character_face, user: @user)
    outfit = create(:outfit, user: @user, character_face: face)
    sign_in @user

    assert_api_response :delete, 200, api_path: "/character-faces/{id}", path_params: {id: face.id}

    assert_nil outfit.reload.character_face_id
  end

  test "GET /character-faces/shared/{token} shows the resolved character to anyone holding the token" do
    import_customizer
    face = create(:character_face, user: @user, name: "Macken")
    hair = CharacterAsset.create!(path: "characters/male/chf/geometry/m_hair_32.glb", etag: "x")
    hair.file.attach(io: StringIO.new("glb"), filename: "m_hair_32.glb")

    assert_api_response :get, 200, api_path: "/character-faces/shared/{token}", path_params: {token: face.token} do
      character = parsed_body["character"]
      assert_equal "Macken", parsed_body["name"]
      assert_equal "male", character["body"]
      assert_equal [[27, 1.0]], character.dig("face", "weights", 0, "heads")
      assert_nil character["assets"]
      assert_includes character["hidden_parts"].keys, "hair_itemport"
      assert character.dig("skin", "body_baseColorFactor")
      assert(character["meshes"].all? { |mesh| mesh.key?("materials_by_submaterial") })
      assert_includes character["meshes"].find { |mesh| mesh["port"] == "hair_itemport" }["headwear"].keys, "hatHair_mask"

      meshes = character["meshes"].index_by { |mesh| mesh["port"] }
      assert_match %r{/rails/active_storage/blobs/.+/m_hair_32\.glb}, meshes.dig("hair_itemport", "url")
      assert_nil meshes.dig("beard_itemport", "url"), "not imported, so not served"
    end
  end

  test "GET /character-faces/shared/{token} serves the character without a resolution until the export is imported" do
    face = create(:character_face, user: @user)

    assert_api_response :get, 200, api_path: "/character-faces/shared/{token}", path_params: {token: face.token} do
      assert_nil parsed_body["character"]
      assert parsed_body.dig("file", "url").present?
    end
  end

  test "GET /character-faces/shared/{token} resolves again once the catalogue changed" do
    import_customizer
    face = create(:character_face, user: @user)
    face.character
    digest = face.reload.resolved_digest

    CharacterAsset.find_by!(path: Chf::Context::CATALOG).update!(etag: "catalog-2")
    get "/api/v1/character-faces/shared/#{face.token}"

    assert_response :ok
    assert_not_equal digest, face.reload.resolved_digest
  end

  test "GET /character-faces/shared/{token} still hands out the file when the export cannot be resolved" do
    import_customizer
    face = create(:character_face, user: @user)
    Chf::Resolver.any_instance.stubs(:spec).raises(ArgumentError, "unexpected export")

    assert_api_response :get, 200, api_path: "/character-faces/shared/{token}", path_params: {token: face.token} do
      assert_nil parsed_body["character"]
      assert parsed_body.dig("file", "url").present?
    end
  end

  test "PUT /character-faces/{id} names the download after the character" do
    face = create(:character_face, user: @user, name: "Old")
    sign_in @user

    assert_api_response :put, 200, api_path: "/character-faces/{id}", path_params: {id: face.id}, body: {name: "Bob"} do
      assert_equal "Bob.chf", parsed_body.dig("file", "name")
    end
  end

  test "GET /character-faces/shared/{token} is not found for an unknown token" do
    assert_api_response :get, 404, api_path: "/character-faces/shared/{token}", path_params: {token: "nope"}
  end
end
