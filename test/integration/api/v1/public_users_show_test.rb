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

  test "GET /public/users/:username flags a supporter" do
    user = create(:user, :public_hangar)
    create(:supporter_contribution, user:, started_at: Date.current)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal true, parsed_body["supporter"]
    end
  end

  test "GET /public/users/:username does not flag an anonymous supporter" do
    user = create(:user, :public_hangar)
    create(:supporter_contribution, :anonymous, user:, started_at: Date.current)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal false, parsed_body["supporter"]
    end
  end

  test "GET /public/users/:username does not flag a plain user" do
    user = create(:user, :public_hangar)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal false, parsed_body["supporter"]
    end
  end

  test "GET /public/users/:username returns 404 when hangar is private" do
    user = create(:user, :private_hangar)

    assert_api_response :get, 404, path_params: {username: user.username}
  end

  test "GET /public/users/:username returns 404 for unknown username" do
    assert_api_response :get, 404, path_params: {username: "not-a-user"}
  end
end
