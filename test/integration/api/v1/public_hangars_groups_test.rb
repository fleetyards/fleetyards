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

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/HangarGroupPublic"}
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
end
