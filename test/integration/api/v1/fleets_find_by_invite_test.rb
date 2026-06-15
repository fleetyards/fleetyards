# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsFindByInviteTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/find-by-invite/{token}" do
    parameter name: "token", in: :path, schema: {type: :string}, description: "Fleet Invite Token"

    post("Find Fleet by Invite") do
      operationId "findFleetByInvite"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "POST /fleets/find-by-invite/:token returns the fleet" do
    fleet = create(:fleet)
    invite = create(:fleet_invite_url, fleet: fleet)
    sign_in @user

    assert_api_response :post, 200, path_params: {token: invite.token} do
      assert_equal fleet.id, parsed_body["id"]
    end
  end

  test "POST /fleets/find-by-invite/:token returns 401 when not signed in" do
    fleet = create(:fleet)
    invite = create(:fleet_invite_url, fleet: fleet)

    assert_api_response :post, 401, path_params: {token: invite.token}
  end

  test "POST /fleets/find-by-invite/:token with OAuth bearer token" do
    fleet = create(:fleet)
    invite = create(:fleet_invite_url, fleet: fleet)

    assert_api_response :post, 200,
      path_params: {token: invite.token},
      headers: oauth_headers_for(@user, scopes: ["fleet", "fleet:read"])
  end

  test "POST /fleets/find-by-invite/:token returns 401 for OAuth token with wrong scope" do
    fleet = create(:fleet)
    invite = create(:fleet_invite_url, fleet: fleet)

    assert_api_response :post, 401,
      path_params: {token: invite.token},
      headers: oauth_headers_for(@user, scopes: ["public"])
  end
end
