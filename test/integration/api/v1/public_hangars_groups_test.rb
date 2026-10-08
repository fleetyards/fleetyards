# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicHangarsGroupsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/hangars/{username}/groups" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username", required: true

    get("HangarGroup list") do
      operationId "publicHangarGroups"
      tags "PublicHangarGroups"
      produces "application/json"

      parameter name: "share", in: :query, schema: {type: :string}, required: false, description: "Hangar share token"

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::Groups::PublicHangarGroupsList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /public/hangars/:username/groups returns the public groups" do
    user = create(:user, public_hangar: true)
    create_list(:hangar_group, 3, :public, user: user)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal 3, parsed_body.size
    end
  end

  test "GET /public/hangars/:username/groups opens a private hangar's groups to its share token" do
    user = create(:user, public_hangar: false)
    create_list(:hangar_group, 2, :public, user: user)
    token = user.ensure_hangar_share_token!

    assert_api_response :get, 200, path_params: {username: user.username}, params: {share: token} do
      assert_equal 2, parsed_body.size
    end
  end

  test "GET /public/hangars/:username/groups returns 404 for a private hangar" do
    user = create(:user, public_hangar: false)

    assert_api_response :get, 404, path_params: {username: user.username}
  end
end
