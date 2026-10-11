# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetMemberHealthTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/members/health" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Fleet Member Health") do
      operationId "fleetMemberHealth"
      tags "FleetMembers"
      produces "application/json"

      parameter name: "inactiveDays", in: :query, schema: {type: :integer, minimum: 1, default: 30}, required: false,
        description: "Days without activity after which a member counts as inactive"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetMemberHealth
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user, last_active_at: 1.hour.ago)
    @gone = create(:user, last_active_at: 90.days.ago)
    @away = create(:user, last_active_at: 40.days.ago)
    @never = create(:user)
    @never.update_columns(last_active_at: nil)
    @recent = create(:user, last_active_at: 10.days.ago)
    @fleet = create(:fleet, admins: [@admin], members: [@gone, @away, @never, @recent])
  end

  test "GET health lists inactive members, longest gone first" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      inactive = parsed_body["inactiveMembers"]

      assert_equal 30, parsed_body["inactiveDays"]
      assert_equal 3, inactive["totalCount"]
      assert_equal [@never, @gone, @away].map(&:username), inactive["items"].pluck("username")
    end
  end

  test "GET health takes the inactive threshold from inactiveDays" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {inactiveDays: 60} do
      assert_equal 60, parsed_body["inactiveDays"]
      assert_equal [@never, @gone].map(&:username), parsed_body["inactiveMembers"]["items"].pluck("username")
    end
  end

  test "GET health leaves out members who have not joined" do
    create(:fleet_membership, :requested, fleet: @fleet, user: create(:user, last_active_at: 90.days.ago))
    @fleet.fleet_memberships.find_by(user: @away).discard
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal [@never, @gone].map(&:username), parsed_body["inactiveMembers"]["items"].pluck("username")
    end
  end

  test "GET health has no unverified section without an RSI SID" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil parsed_body["unverifiedMembers"]
    end
  end

  test "GET health lists members the fleet's RSI org does not know" do
    @fleet.update_columns(rsi_sid: "TESTORG")
    @fleet.fleet_memberships.where.not(user: [@gone, @recent]).update_all(verified: true)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      unverified = parsed_body["unverifiedMembers"]

      assert_equal false, parsed_body["fleetRsiVerified"]
      assert_equal 2, unverified["totalCount"]
      assert_equal [@gone, @recent].map(&:username).sort, unverified["items"].pluck("username").sort
    end
  end

  test "GET health lists roles nobody holds" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["officer"], parsed_body["emptyRoles"].pluck("slug")
    end
  end

  test "GET health leaves out empty roles for a reader who cannot read roles" do
    role = create(:fleet_role, fleet: @fleet, name: "Recruiter", resource_access: ["fleet:memberships:read", "fleet:memberships:update"])
    recruiter = create(:user)
    create(:fleet_membership, fleet: @fleet, user: recruiter, fleet_role: role, aasm_state: :accepted)
    sign_in recruiter

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil parsed_body["emptyRoles"]
      assert_equal 3, parsed_body["inactiveMembers"]["totalCount"]
    end
  end

  test "GET health returns 403 for a member who cannot update members" do
    sign_in @recent

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET health returns 403 for a role that updates members without reading them" do
    role = create(:fleet_role, fleet: @fleet, name: "Promoter", resource_access: ["fleet:memberships:update"])
    promoter = create(:user)
    create(:fleet_membership, fleet: @fleet, user: promoter, fleet_role: role, aasm_state: :accepted)
    sign_in promoter

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET health returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET health with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
