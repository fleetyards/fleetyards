# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsVehiclesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Public Fleet Vehicles List") do
      operationId "publicFleetVehicles"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetVehicleQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "grouped", in: :query, schema: {type: :boolean}, required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetPublicVehicles
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Sidekiq::Testing.inline!
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "GET /public/fleets/:fleetSlug/vehicles returns vehicle list" do
    member = create(:user, vehicle_count: 2)
    fleet = create(:fleet, public_fleet: true, members: [member])

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /public/fleets/:fleetSlug/vehicles filters by modelNameCont" do
    member = create(:user, vehicle_count: 2)
    fleet = create(:fleet, public_fleet: true, members: [member])

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {q: {"modelNameCont" => member.vehicles.first.model.name}} do
      assert_equal 1, parsed_body["items"].count
      assert_equal member.vehicles.first.model.name, parsed_body["items"].first.dig("model", "name")
    end
  end

  test "GET /public/fleets/:fleetSlug/vehicles honours perPage" do
    member = create(:user, vehicle_count: 2)
    fleet = create(:fleet, public_fleet: true, members: [member])

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug}, params: {perPage: 1} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /public/fleets/:fleetSlug/vehicles honours grouped" do
    member = create(:user, vehicle_count: 2)
    fleet = create(:fleet, public_fleet: true, members: [member])

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug}, params: {grouped: true} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /public/fleets/:fleetSlug/vehicles is open to an allied fleet" do
    member = create(:user, vehicle_count: 2)
    fleet = create(:fleet, public_fleet: false, allies_fleet: true, members: [member])
    reader = create(:user)
    allied_fleet = create(:fleet, created_by: reader.id)
    create(:fleet_alliance, :accepted, requester: fleet, addressee: allied_fleet)
    sign_in reader

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /public/fleets/:fleetSlug/vehicles stays closed to a stranger when only allies are admitted" do
    fleet = create(:fleet, public_fleet: false, allies_fleet: true, members: [create(:user, vehicle_count: 1)])
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {fleetSlug: fleet.slug}
  end

  # This endpoint authorizes against `show?`, so sharing the numbers must not
  # also hand over the ship list with its loadouts, modules and owner avatars.
  test "GET /public/fleets/:fleetSlug/vehicles is closed to an ally given only the stats" do
    fleet = create(:fleet, public_fleet: false, public_fleet_stats: false,
      allies_fleet: false, allies_fleet_stats: true,
      members: [create(:user, vehicle_count: 1)])
    reader = create(:user)
    allied_fleet = create(:fleet, created_by: reader.id)
    create(:fleet_alliance, :accepted, requester: fleet, addressee: allied_fleet)
    sign_in reader

    assert_api_response :get, 404, path_params: {fleetSlug: fleet.slug}
  end

  # The ally view reads `fleet.vehicles`, which is FleetVehicle rows that each
  # member's own ships_filter already decided the contents of. Nothing in this
  # feature re-applies that rule, so this is the test that it is still applied.
  test "GET /public/fleets/:fleetSlug/vehicles hides a member who hid their ships from an ally too" do
    hidden_member = create(:user, vehicle_count: 2)
    shown_member = create(:user, vehicle_count: 1)
    fleet = create(:fleet, public_fleet: false, allies_fleet: true, members: [hidden_member, shown_member])
    fleet.fleet_memberships.find_by(user: hidden_member).update!(ships_filter: :hide)

    reader = create(:user)
    allied_fleet = create(:fleet, created_by: reader.id)
    create(:fleet_alliance, :accepted, requester: fleet, addressee: allied_fleet)
    sign_in reader

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /public/fleets/:fleetSlug/vehicles returns 404 for non-public fleet" do
    fleet = create(:fleet, public_fleet: false)

    assert_api_response :get, 404, path_params: {fleetSlug: fleet.slug}
  end

  test "GET /public/fleets/:fleetSlug/vehicles returns 404 for unknown slug" do
    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end
end
