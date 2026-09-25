# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronMembersIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Fleet Squadron Members List") do
      operationId "fleetSquadronMembers"
      tags "FleetSquadrons"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetSquadronMemberQuery,
        style: :deepObject,
        explode: true,
        required: false

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
    Flipper.enable("fleet_squadrons")
    @admin = create(:user)
    @member = create(:user)
    @outsider_of_squadron = create(:user)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], members: [@member, @outsider_of_squadron])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug}
  end

  test "GET squadron members lists only the squadron's members" do
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@member.username], parsed_body["items"].map { |entry| entry["username"] }
    end
  end

  # By when they joined this squadron: a team the member joined in between is a
  # different date, and must neither decide the order nor list them twice.
  test "GET squadron members sorts by when they joined this squadron" do
    @squadron.fleet_squadron_memberships.update_all(created_at: 2.days.ago)
    later = @fleet.fleet_memberships.kept.find_by(user: @outsider_of_squadron)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: later, created_at: 1.day.ago)
    team = create(:fleet_squadron, fleet: @fleet, team: true)
    create(:fleet_squadron_membership, fleet_squadron: team, fleet_membership: @membership, created_at: 1.hour.ago)
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params, params: {q: {s: "squadronMembershipCreatedAt asc"}} do
      assert_equal [@member.username, @outsider_of_squadron.username], parsed_body["items"].map { |entry| entry["username"] }
    end

    assert_api_response :get, 200, path_params: path_params, params: {q: {s: "squadronMembershipCreatedAt desc"}} do
      assert_equal [@outsider_of_squadron.username, @member.username], parsed_body["items"].map { |entry| entry["username"] }
    end
  end

  test "GET squadron members filters by when they joined this squadron, not a team" do
    @squadron.fleet_squadron_memberships.update_all(created_at: 10.days.ago)
    team = create(:fleet_squadron, fleet: @fleet, team: true)
    create(:fleet_squadron_membership, fleet_squadron: team, fleet_membership: @membership, created_at: 1.day.ago)
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params,
      params: {q: {squadronMembershipCreatedAtGteq: 3.days.ago.to_date.iso8601}} do
      assert_empty parsed_body["items"]
    end

    assert_api_response :get, 200, path_params: path_params,
      params: {q: {squadronMembershipCreatedAtLteq: 3.days.ago.to_date.iso8601}} do
      assert_equal [@member.username], parsed_body["items"].map { |entry| entry["username"] }
    end
  end

  test "GET squadron members is refused to a role that reads squadrons but not the roster" do
    role = create(:fleet_role, fleet: @fleet, name: "Squadrons Only", resource_access: ["fleet:squadrons:read"])
    reader = create(:user)
    create(:fleet_membership, :accepted, fleet: @fleet, user: reader, fleet_role: role)
    sign_in reader

    get "/api/v1/fleets/#{@fleet.slug}/squadrons/#{@squadron.slug}/members"

    assert_response :forbidden
  end

  test "GET squadron members is readable by a plain member" do
    sign_in @member

    assert_api_response :get, 200, path_params: path_params
  end

  # A squadron row survives its member's invitation being withdrawn only until
  # the membership goes, so the list asks for accepted memberships rather than
  # the raw join.
  test "GET squadron members leaves out a member who is no longer accepted" do
    pending = create(:fleet_membership, :invited, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: pending)
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@member.username], parsed_body["items"].map { |entry| entry["username"] }
    end
  end

  test "GET squadron members returns 404 for an unknown squadron" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: "no-such-wing"}
  end

  test "GET squadron members returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: path_params
  end

  test "GET squadron members with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: path_params,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
