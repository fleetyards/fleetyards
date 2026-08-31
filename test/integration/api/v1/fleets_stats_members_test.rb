# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsStatsMembersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/stats/members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Members Stats") do
      operationId "fleetMembersStats"
      tags "FleetStats"
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
    end
  end

  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  test "GET /fleets/:slug/stats/members returns member stats" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}
  end

  # The role breakdown is a grouped count, so a sort reaching ransack puts an
  # ungrouped column in the ORDER BY and Postgres rejects the whole query.
  test "GET /fleets/:slug/stats/members ignores sort params" do
    create(:user).tap { |user| @fleet.fleet_memberships.create!(user:, fleet_role: @fleet.default_member_role, aasm_state: "accepted") }
    sign_in @admin

    ["s", "sorts"].each do |key|
      assert_api_response :get, 200,
        path_params: {fleetSlug: @fleet.slug},
        params: {q: {key => "username asc"}} do
        assert_equal 2, parsed_body["total"]
      end
    end
  end

  test "GET /fleets/:slug/stats/members returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/members with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
