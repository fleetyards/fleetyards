# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInvitesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/invites" do
    get("Fleet Invites current User") do
      operationId "fleetInvites"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FleetMember"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "GET /fleets/invites lists the user's invites" do
    create_list(:fleet_membership, 2, user: @user, aasm_state: :invited)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body.size
    end
  end

  test "GET /fleets/invites returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /fleets/invites with OAuth bearer token" do
    create_list(:fleet_membership, 2, user: @user, aasm_state: :invited)

    assert_api_response :get, 200, headers: oauth_headers_for(@user, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/invites returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401, headers: oauth_headers_for(@user, scopes: ["public"])
  end
end
