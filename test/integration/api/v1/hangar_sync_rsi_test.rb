# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::HangarSyncRsiTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/sync-rsi-hangar" do
    put("Sync RSI Hangar") do
      operationId "syncRsiHangar"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/SyncRsiHangarInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarSyncSubmitResult"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "PUT /hangar/sync-rsi-hangar submits a sync" do
    user = create(:user)
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}]}
    assert_api_response :put, 200, body: body
  end

  test "PUT /hangar/sync-rsi-hangar returns 400 for missing body" do
    user = create(:user)
    sign_in user

    assert_api_response :put, 400, body: nil
  end

  test "PUT /hangar/sync-rsi-hangar returns 401 when not signed in" do
    body = {items: [{id: "1", name: "x", type: "ship"}]}
    assert_api_response :put, 401, body: body
  end

  test "PUT /hangar/sync-rsi-hangar with OAuth bearer token" do
    user = create(:user)
    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}]}

    assert_api_response :put, 200,
      headers: oauth_headers_for(user, scopes: ["hangar", "hangar:write"]),
      body: body
  end
end
