# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::PublicHangarsEmbedTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/hangars/embed" do
    get("Public Hangar embed") do
      operationId "publicHangarEmbed"
      tags "PublicHangar"
      produces "application/json"

      parameter name: :usernames, in: :query,
        schema: {"$ref": "#/components/schemas/HangarEmbedQuery"},
        style: :deepObject,
        explode: true,
        required: true

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/VehiclePublic"}
      end
    end
  end

  test "GET /public/hangars/embed returns the user's public vehicles" do
    user = create(:user)
    create_list(:vehicle, 2, user: user, public: true)

    assert_api_response :get, 200, params: {usernames: [user.username]} do
      assert_operator parsed_body.count, :>, 0
    end
  end

  test "GET /public/hangars/embed returns an empty list for non-public hangar" do
    user = create(:user, public_hangar: false)
    create_list(:vehicle, 2, user: user, public: true)

    assert_api_response :get, 200, params: {usernames: [user.username]} do
      assert_equal 0, parsed_body.count
    end
  end

  test "GET /public/hangars/embed returns an empty list for an unknown username" do
    assert_api_response :get, 200, params: {usernames: ["not-a-user"]} do
      assert_equal 0, parsed_body.count
    end
  end
end
