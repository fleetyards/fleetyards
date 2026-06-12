# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::PublicHangarsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/hangars/{username}" do
    parameter name: "username", in: :path, schema: {type: :string}, required: true

    get("Public Hangar") do
      operationId "publicHangar"
      tags "PublicHangar"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Vehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarPublic"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /public/hangars/:username returns the user's public vehicles" do
    user = create(:user, :public_hangar)
    model = create(:model, :with_store_image, :with_description)
    create(:vehicle, :public, user: user)
    create(:vehicle, :public, :with_name, user: user, model: model)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /public/hangars/:username filters by query" do
    user = create(:user, :public_hangar)
    vehicles = [create(:vehicle, :public, user: user), create(:vehicle, :public, user: user)]

    assert_api_response :get, 200,
      path_params: {username: user.username},
      params: {q: {"modelNameOrModelDescriptionCont" => vehicles.first.model.name}} do
      assert_equal 1, parsed_body["items"].count
      assert_equal vehicles.first.model.name, parsed_body["items"].first.dig("model", "name")
    end
  end

  test "GET /public/hangars/:username honours perPage" do
    user = create(:user, :public_hangar)
    create_list(:vehicle, 2, :public, user: user)

    assert_api_response :get, 200,
      path_params: {username: user.username},
      params: {perPage: 1} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /public/hangars/:username returns 404 for private hangar" do
    user = create(:user, :private_hangar)

    assert_api_response :get, 404, path_params: {username: user.username}
  end

  test "GET /public/hangars/:username returns 404 for unknown username" do
    assert_api_response :get, 404, path_params: {username: "not-a-user"}
  end
end
