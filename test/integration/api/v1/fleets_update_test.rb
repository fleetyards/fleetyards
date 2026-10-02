# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "slug"

    put("Update Fleet") do
      operationId "updateFleet"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Fleet
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "You are not an Admin or Officer of this Fleet") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "PUT /fleets/:slug updates the fleet" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {slug: @fleet.slug},
      body: {discord: "https://discord.gg/1234567890"} do
      assert_equal "discord.gg/1234567890", parsed_body["discord"]
    end
  end

  test "PUT /fleets/:slug sets the headquarters, linked to one of our places" do
    levski = create(:location, name: "Levski", kind: "city")
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {slug: @fleet.slug},
      body: {headquartersLocationId: levski.id} do
      assert_equal "Levski", parsed_body["headquarters"]
      assert_equal levski.slug, parsed_body.dig("headquartersLocation", "slug")
    end
  end

  test "PUT /fleets/:slug switches squadrons on" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {slug: @fleet.slug},
      body: {squadronsEnabled: true} do
      assert parsed_body["squadronsEnabled"]
    end

    assert @fleet.reload.squadrons_enabled?
  end

  test "PUT /fleets/:slug lets a manager take the fleet out of the directory" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {slug: @fleet.slug},
      body: {listed: false, alignment: "lawful"} do
      assert_equal false, parsed_body["listed"]
      assert_equal "lawful", parsed_body["alignment"]
    end

    assert_equal false, @fleet.reload.listed
  end

  test "PUT /fleets/:slug leaves the directory choice to managers" do
    editor = create(:user)
    role = @fleet.fleet_roles.create!(name: "Editor", rank: 90, resource_access: ["fleet:update"])
    create(:fleet_membership, fleet: @fleet, user: editor, fleet_role: role, aasm_state: :accepted)
    sign_in editor

    assert_api_response :put, 200,
      path_params: {slug: @fleet.slug},
      body: {listed: false, alignment: "outlaw"} do
      assert_nil parsed_body["listed"]
      assert_equal "outlaw", parsed_body["alignment"]
    end

    assert_nil @fleet.reload.listed
  end

  test "PUT /fleets/:slug returns 404 for unknown slug" do
    sign_in @admin

    assert_api_response :put, 404, path_params: {slug: "unknown-fleet"}, body: {discord: "x"}
  end

  test "PUT /fleets/:slug returns 403 for a member" do
    sign_in @member

    assert_api_response :put, 403, path_params: {slug: @fleet.slug}, body: {discord: "x"}
  end

  test "PUT /fleets/:slug returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {slug: @fleet.slug}, body: {discord: "x"}
  end

  test "PUT /fleets/:slug with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {slug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {discord: "https://discord.gg/1234567890"}
  end

  test "PUT /fleets/:slug returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {slug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {discord: "x"}
  end
end
