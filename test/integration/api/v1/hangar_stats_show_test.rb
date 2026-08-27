# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarStatsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/stats" do
    get("Your Hangar Stats") do
      operationId "hangarStats"
      tags "HangarStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::HangarQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::HangarStats
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /hangar/stats returns the user's hangar stats" do
    user = create(:user, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200
  end

  test "GET /hangar/stats excludes the classifications in classificationNotIn" do
    user = create(:user)
    create(:vehicle, user:, model: create(:model, classification: :combat))
    create(:vehicle, user:, model: create(:model, classification: :transport))
    sign_in user

    assert_api_response :get, 200, params: {q: {"classificationNotIn" => ["combat"]}} do
      assert_equal 1, parsed_body["total"]
    end
  end

  # The counts are deliberately blind to their own filter, as the group counts
  # are: a chip that reads 0 the moment you exclude it leaves nothing to click to
  # undo the exclusion.
  test "GET /hangar/stats keeps the classification counts when one is excluded" do
    user = create(:user)
    create(:vehicle, user:, model: create(:model, classification: :combat))
    create(:vehicle, user:, model: create(:model, classification: :transport))
    sign_in user

    assert_api_response :get, 200, params: {q: {"classificationNotIn" => ["combat"]}} do
      combat = parsed_body["classifications"].find { |item| item["name"] == "combat" }

      assert_equal 1, combat["count"]
    end
  end

  test "GET /hangar/stats returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/stats with OAuth bearer token" do
    user = create(:user, vehicle_count: 3)

    assert_api_response :get, 200, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:read"])
  end
end
