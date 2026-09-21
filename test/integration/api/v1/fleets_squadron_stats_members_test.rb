# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronStatsMembersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/stats/members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Fleet Squadron Members Stats") do
      operationId "fleetSquadronMembersStats"
      tags "FleetSquadrons"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetMemberQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetMembersStats
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
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug}
  end

  test "GET squadron member stats counts only the squadron" do
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal 1, parsed_body["total"]
    end
  end

  test "GET squadron member stats breaks the count down by role" do
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal({"member" => 1}, parsed_body["metrics"]["membersByRole"])
    end
  end

  test "GET squadron member stats is zero for a squadron with nobody in it" do
    empty = create(:fleet_squadron, fleet: @fleet)
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: empty.slug} do
      assert_equal 0, parsed_body["total"]
    end
  end

  test "GET squadron member stats returns 404 for an unknown squadron" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: "no-such-wing"}
  end

  test "GET squadron member stats returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: path_params
  end

  test "GET squadron member stats with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: path_params,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
