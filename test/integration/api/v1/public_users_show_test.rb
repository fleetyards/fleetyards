# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicUsersShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/users/{username}" do
    parameter name: "username", in: :path, schema: {type: :string}, required: true

    get("Public User") do
      operationId "publicUser"
      tags "PublicUser"
      produces "application/json"

      parameter name: "share", in: :query, schema: {type: :string}, required: false, description: "Hangar share token"

      response(200, "successful") do
        schema ::V1::Schemas::UserPublic
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /public/users/:username returns the user when hangar is public" do
    user = create(:user, :with_avatar, :with_rsi_handle, :with_social_links, :public_hangar)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal user.username, parsed_body["username"]
    end
  end

  test "GET /public/users/:username carries the display name" do
    user = create(:user, :public_hangar, display_name: "Torlek Maru")

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal user.username, parsed_body["username"]
      assert_equal "Torlek Maru", parsed_body["displayName"]
    end
  end

  test "GET /public/users/:username flags a supporter" do
    user = create(:user, :public_hangar)
    create(:supporter_contribution, user:, started_at: Date.current)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal true, parsed_body["supporter"]
    end
  end

  test "GET /public/users/:username flags a maintainer" do
    user = create(:user, :public_hangar, maintainer: true)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal true, parsed_body["maintainer"]
      assert_equal 3, parsed_body["supporterTier"]
    end
  end

  # Anonymity keeps a contribution off the supporters page by name; it is not a
  # secret about whether somebody supports, so the badge is unaffected.
  test "GET /public/users/:username flags an anonymous supporter too" do
    user = create(:user, :public_hangar)
    create(:supporter_contribution, :anonymous, user:, started_at: Date.current)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal true, parsed_body["supporter"]
    end
  end

  test "GET /public/users/:username carries the supporter tier" do
    user = create(:user, :public_hangar)
    create(:supporter_contribution, user:, amount_cents: 600, started_at: Date.current)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal 2, parsed_body["supporterTier"]
    end
  end

  test "GET /public/users/:username does not flag a plain user" do
    user = create(:user, :public_hangar)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal false, parsed_body["supporter"]
      assert_equal 0, parsed_body["supporterTier"]
    end
  end

  test "GET /public/users/:username returns 404 when hangar is private" do
    user = create(:user, :private_hangar)

    assert_api_response :get, 404, path_params: {username: user.username}
  end

  test "GET /public/users/:username returns 404 for unknown username" do
    assert_api_response :get, 404, path_params: {username: "not-a-user"}
  end

  test "GET /public/users/:username returns a private hangar's owner to its share token" do
    user = create(:user, :private_hangar)
    token = user.ensure_hangar_share_token!

    assert_api_response :get, 200, path_params: {username: user.username}, params: {share: token}
  end

  test "GET /public/users/:username does not take another user's share token" do
    user = create(:user, :private_hangar)
    other_token = create(:user).ensure_hangar_share_token!

    assert_api_response :get, 404, path_params: {username: user.username}, params: {share: other_token}
  end

  test "GET /public/users/:username tells a friend whether the user is online" do
    UserPresence.reset!
    user = create(:user, :public_hangar)
    friend = create(:user)
    create(:friendship, :accepted, requester: friend, addressee: user)
    UserPresence.connect(user.id, "tab-1")
    sign_in friend

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal true, parsed_body["online"]
    end
  ensure
    UserPresence.reset!
  end

  test "GET /public/users/:username tells a fleet mate whether the user is online" do
    user = create(:user, :public_hangar)
    mate = create(:user)
    create(:fleet, members: [user, mate])
    sign_in mate

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal false, parsed_body["online"]
    end
  end

  test "GET /public/users/:username says nothing about presence to anyone else" do
    user = create(:user, :public_hangar)
    sign_in create(:user)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_not parsed_body.key?("online")
    end
  end

  test "GET /public/users/:username carries the default outfit to open in the dressing room" do
    user = create(:user, :public_hangar, public_character_face: true)
    face = create(:character_face, user:)
    core = create(:worn_equipment, slot: "torso")
    outfit = create(:outfit, user:, character_face: face)
    outfit.update!(item_list: [{slot: "torso", equipment_id: core.id}])
    user.update!(default_outfit: outfit)

    assert_api_response :get, 200, path_params: {username: user.username} do
      character = parsed_body["character"]
      assert_equal face.token, character["characterToken"]
      assert_equal [{"slot" => "torso", "slug" => core.slug}], character["items"]
    end
  end

  test "GET /public/users/:username has no character without a default outfit" do
    user = create(:user, :public_hangar)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_nil parsed_body["character"]
    end
  end

  test "GET /public/users/:username keeps the character to the game's default face unless the user shows their own" do
    user = create(:user, :public_hangar)
    outfit = create(:outfit, user:, character_face: create(:character_face, user:))
    user.update!(default_outfit: outfit)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_nil parsed_body["character"]["characterToken"]
    end
  end

  test "GET /public/users/:username shows the helmet portrait even when the user shows their own character" do
    user = create(:user, :public_hangar)
    user.update!(default_outfit: create(:outfit, user:))
    user.character_avatar_helmet.attach(io: Rails.root.join("test/fixtures/files/test.png").open, filename: "helmet.png")
    user.character_avatar_bare.attach(io: Rails.root.join("test/fixtures/files/test.png").open, filename: "bare.png")

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal "helmet.png", parsed_body["characterPortrait"]["name"]
    end

    user.update!(public_character_face: true)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal "helmet.png", parsed_body["characterPortrait"]["name"]
    end
  end

  test "GET /public/users/:username carries the public flagship" do
    user = create(:user, :public_hangar)
    vehicle = create(:vehicle, user:, flagship: true, public: true)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal vehicle.model.slug, parsed_body["flagship"]["modelSlug"]
      assert_equal vehicle.model.manufacturer.name, parsed_body["flagship"]["manufacturerName"]
    end
  end
end
