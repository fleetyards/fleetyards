# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::PublicFleetsVehiclesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Public Fleet Vehicles List") do
      operationId "publicFleetVehicles"
      tags "Fleets"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "grouped", in: :query, schema: {type: :boolean}, required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetPublicVehicles"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
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

  test "GET /public/fleets/:fleetSlug/vehicles returns 404 for non-public fleet" do
    fleet = create(:fleet, public_fleet: false)

    assert_api_response :get, 404, path_params: {fleetSlug: fleet.slug}
  end

  test "GET /public/fleets/:fleetSlug/vehicles returns 404 for unknown slug" do
    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end
end
