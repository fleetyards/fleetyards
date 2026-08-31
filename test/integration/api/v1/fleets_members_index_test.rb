# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMembersIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Member List") do
      operationId "fleetMembers"
      tags "FleetMembers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetMemberQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetMembersList
      end

      response(401, "unauthorized") do
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
    @another_member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member, @another_member])
  end

  test "GET /fleets/:slug/members lists all members" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/members filters by usernameCont" do
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"usernameCont" => @member.username}} do
      assert_equal 1, parsed_body["items"].count
      assert_equal @member.username, parsed_body["items"].first["username"]
    end
  end

  test "GET /fleets/:slug/members honours perPage" do
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {perPage: 1} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/members is accessible to a non-admin member" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/members sorts by rsiHandle asc" do
    @admin.update!(rsi_handle: "charlie")
    @member.update!(rsi_handle: "alpha")
    @another_member.update!(rsi_handle: "bravo")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"sorts" => "rsiHandle asc"}} do
      assert_equal %w[alpha bravo charlie], parsed_body["items"].map { |m| m["rsiHandle"] }
    end
  end

  test "GET /fleets/:slug/members sorts by rsiHandle desc" do
    @admin.update!(rsi_handle: "charlie")
    @member.update!(rsi_handle: "alpha")
    @another_member.update!(rsi_handle: "bravo")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"sorts" => "rsiHandle desc"}} do
      assert_equal %w[charlie bravo alpha], parsed_body["items"].map { |m| m["rsiHandle"] }
    end
  end

  test "GET /fleets/:slug/members sorts by username via the s param" do
    @admin.update!(username: "charlie")
    @member.update!(username: "alpha")
    @another_member.update!(username: "bravo")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"s" => "username asc"}} do
      assert_equal %w[alpha bravo charlie], parsed_body["items"].map { |m| m["username"] }
    end

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"s" => "username desc"}} do
      assert_equal %w[charlie bravo alpha], parsed_body["items"].map { |m| m["username"] }
    end
  end

  test "GET /fleets/:slug/members sorts by rsiHandle via the s param" do
    @admin.update!(rsi_handle: "charlie")
    @member.update!(rsi_handle: "alpha")
    @another_member.update!(rsi_handle: "bravo")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"s" => "rsiHandle asc"}} do
      assert_equal %w[alpha bravo charlie], parsed_body["items"].map { |m| m["rsiHandle"] }
    end
  end

  test "GET /fleets/:slug/members sorts by acceptedAt via the s param" do
    @fleet.fleet_memberships.find_by(user: @admin).update!(accepted_at: 3.days.ago)
    @fleet.fleet_memberships.find_by(user: @member).update!(accepted_at: 1.day.ago)
    @fleet.fleet_memberships.find_by(user: @another_member).update!(accepted_at: 2.days.ago)
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"s" => "acceptedAt asc"}} do
      assert_equal [@admin.username, @another_member.username, @member.username],
        parsed_body["items"].map { |m| m["username"] }
    end
  end

  # Only the two members the request does not authenticate as, because
  # `set_last_active_at` refreshes the requesting user's own timestamp.
  test "GET /fleets/:slug/members sorts by lastActiveAt via the s param" do
    @member.update!(last_active_at: 1.day.ago)
    @another_member.update!(last_active_at: 2.days.ago)
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"s" => "lastActiveAt asc"}} do
      usernames = parsed_body["items"].map { |m| m["username"] }

      assert_operator usernames.index(@another_member.username), :<,
        usernames.index(@member.username)
      assert_equal @admin.username, usernames.last
    end
  end

  # An explicit `sorts` is the caller being specific, so it must not be
  # overwritten by the `s` the table header always appends to the URL.
  test "GET /fleets/:slug/members prefers sorts over s" do
    @admin.update!(username: "charlie")
    @member.update!(username: "alpha")
    @another_member.update!(username: "bravo")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"s" => "username asc", "sorts" => "username desc"}} do
      assert_equal %w[charlie bravo alpha], parsed_body["items"].map { |m| m["username"] }
    end
  end

  test "GET /fleets/:slug/members returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET /fleets/:slug/members returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/members with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
