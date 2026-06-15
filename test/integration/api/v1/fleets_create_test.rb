# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets" do
    post("Create Fleet") do
      operationId "createFleet"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Fleet"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "POST /fleets creates a fleet" do
    sign_in @user

    assert_api_response :post, 201, body: {fid: "STARFLEET", name: "Starfleet"} do
      assert_equal "Starfleet", parsed_body["name"]
    end
  end

  test "POST /fleets returns 400 for missing body" do
    sign_in @user

    assert_api_response :post, 400, body: nil
  end

  test "POST /fleets returns 401 when not signed in" do
    assert_api_response :post, 401, body: {fid: "STF", name: "Starfleet"}
  end

  test "POST /fleets with OAuth bearer token" do
    assert_api_response :post, 201,
      headers: oauth_headers_for(@user, scopes: ["public"]),
      body: {fid: "STARFLEET", name: "Starfleet"}
  end
end
