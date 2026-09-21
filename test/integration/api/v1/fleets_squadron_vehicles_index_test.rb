# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronVehiclesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Fleet Squadron Vehicles List") do
      operationId "fleetSquadronVehicles"
      tags "FleetSquadrons"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetVehicleQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "grouped", in: :query, schema: {type: :boolean}, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetVehicles
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
    Sidekiq::Testing.inline!
    Flipper.enable("fleet_squadrons")
    @admin = create(:user, vehicle_count: 2)
    @member = create(:user, vehicle_count: 3)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug}
  end

  test "GET squadron vehicles lists only the squadron members' ships" do
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal 3, parsed_body["items"].count
      assert_equal [@member.username], parsed_body["items"].map { |entry| entry["username"] }.uniq
    end
  end

  # `where(user_id: [])` is what makes this empty. Dropping the condition for a
  # blank list would hand back the whole fleet's ships instead.
  test "GET squadron vehicles is empty for a squadron with nobody in it" do
    empty = create(:fleet_squadron, fleet: @fleet)
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: empty.slug} do
      assert_empty parsed_body["items"]
    end
  end

  test "GET squadron vehicles is readable by a plain member" do
    sign_in @member

    assert_api_response :get, 200, path_params: path_params
  end

  test "GET squadron vehicles groups by model" do
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params, params: {grouped: true} do
      assert_predicate parsed_body["items"], :present?
    end
  end

  test "GET squadron vehicles returns 404 for an unknown squadron" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: "no-such-wing"}
  end

  test "GET squadron vehicles returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: path_params
  end

  test "GET squadron vehicles with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: path_params,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
