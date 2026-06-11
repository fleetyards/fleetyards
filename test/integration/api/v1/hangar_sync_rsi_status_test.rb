# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::HangarSyncRsiStatusTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/sync-rsi-hangar/status" do
    get("Sync RSI Hangar Status") do
      operationId "syncRsiHangarStatus"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarSyncStatus"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /hangar/sync-rsi-hangar/status returns sync status" do
    user = create(:user)
    sign_in user

    assert_api_response :get, 200
  end

  test "GET /hangar/sync-rsi-hangar/status returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
