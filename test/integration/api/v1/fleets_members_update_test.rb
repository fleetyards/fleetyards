# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMembersUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/members/{username}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username"

    put("Update Member") do
      operationId "updateFleetMember"
      description "Set the nickname a fleet knows a member by"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetMemberUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetMember
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @outsider = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @membership = @fleet.fleet_memberships.find_by(user: @member)
  end

  test "PUT /fleets/:slug/members/:username sets the nickname" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      body: {nickname: "Wingman"} do
      assert_equal "Wingman", parsed_body["nickname"]
      assert_equal @member.username, parsed_body["username"]
    end

    assert_equal "Wingman", @membership.reload.nickname
  end

  test "PUT /fleets/:slug/members/:username clears the nickname with null" do
    @membership.update!(nickname: "Wingman")

    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      body: {nickname: nil} do
      assert_nil parsed_body["nickname"]
    end

    assert_nil @membership.reload.nickname
  end

  test "PUT /fleets/:slug/members/:username treats a blank nickname as cleared" do
    @membership.update!(nickname: "Wingman")

    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      body: {nickname: "   "} do
      assert_nil parsed_body["nickname"]
    end

    assert_nil @membership.reload.nickname
  end

  test "PUT /fleets/:slug/members/:username trims surrounding whitespace" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      body: {nickname: "  Wingman  "} do
      assert_equal "Wingman", parsed_body["nickname"]
    end
  end

  test "PUT /fleets/:slug/members/:username returns 400 for a nickname that is too long" do
    sign_in @admin

    assert_api_response :put, 400,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      body: {nickname: "a" * 256}

    assert_nil @membership.reload.nickname
  end

  # The nickname is the only thing this endpoint may write. Everything else on a
  # membership is either self-service or has its own action, so a fleet admin
  # must not be able to reach it by widening the body. `additionalProperties:
  # false` on the input rejects the request outright; the rule-scoped params
  # filter would drop the extras anyway.
  test "PUT /fleets/:slug/members/:username rejects attributes other than the nickname" do
    hangar_group = create(:hangar_group, user: @member)

    sign_in @admin

    put "/api/v1/fleets/#{@fleet.slug}/members/#{@member.username}",
      params: {nickname: "Wingman", primary: true, shipsFilter: "hide", hangarGroupId: hangar_group.id},
      as: :json

    assert_response :bad_request

    @membership.reload
    assert_nil @membership.nickname
    assert_not @membership.primary
    assert_equal "all", @membership.ships_filter
    assert_nil @membership.hangar_group_id
  end

  test "PUT /fleets/:slug/members/:username returns 403 without membership update access" do
    @fleet.default_member_role.update!(resource_access: ["fleet:memberships:read"])

    sign_in @member

    assert_api_response :put, 403,
      path_params: {fleetSlug: @fleet.slug, username: @admin.username},
      body: {nickname: "Wingman"}
  end

  test "PUT /fleets/:slug/members/:username does not let a member nickname themselves" do
    @fleet.default_member_role.update!(resource_access: ["fleet:memberships:read"])

    sign_in @member

    assert_api_response :put, 403,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      body: {nickname: "Wingman"}

    assert_nil @membership.reload.nickname
  end

  test "PUT /fleets/:slug/members/:username returns 404 for an unknown member" do
    sign_in @admin

    assert_api_response :put, 404,
      path_params: {fleetSlug: @fleet.slug, username: "unknown"},
      body: {nickname: "Wingman"}
  end

  test "PUT /fleets/:slug/members/:username returns 404 for an outsider" do
    sign_in @outsider

    assert_api_response :put, 404,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      body: {nickname: "Wingman"}
  end

  test "PUT /fleets/:slug/members/:username returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      body: {nickname: "Wingman"}
  end

  test "PUT /fleets/:slug/members/:username with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {nickname: "Wingman"}
  end
end
