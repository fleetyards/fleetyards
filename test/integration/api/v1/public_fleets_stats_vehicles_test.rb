# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsStatsVehiclesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/stats/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Public Fleet Vehicles Stats") do
      operationId "publicFleetVehiclesStats"
      tags "FleetStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetVehicleQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/FleetVehiclesStats"
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

  test "GET /public/fleets/:fleetSlug/stats/vehicles counts a looted ship as owned but not as money spent" do
    user = create(:user, vehicle_count: 3)
    fleet = create(:fleet, public_fleet_stats: true, members: [user])
    before = {}

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug} do
      before = {total: parsed_body["total"], money: parsed_body.dig("metrics", "totalMoney")}
    end

    create(:vehicle, user:, public: true, bought_via: :reward_or_loot, model: create(:model, pledge_price: 50),
      model_module_ids: [create(:model_module, pledge_price: 30).id],
      model_upgrade_ids: [create(:model_upgrade, pledge_price: 20).id])

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug} do
      assert_equal before[:total] + 1, parsed_body["total"]
      assert_equal before[:money], parsed_body.dig("metrics", "totalMoney")
    end
  end

  test "GET /public/fleets/:fleetSlug/stats/vehicles returns vehicle stats" do
    member = create(:user, vehicle_count: 3)
    fleet = create(:fleet, public_fleet_stats: true, members: [member])

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug}
  end

  test "GET /public/fleets/:fleetSlug/stats/vehicles returns 404 for non-public stats" do
    fleet = create(:fleet, public_fleet_stats: false)

    assert_api_response :get, 404, path_params: {fleetSlug: fleet.slug}
  end

  test "GET /public/fleets/:fleetSlug/stats/vehicles returns 404 for unknown slug" do
    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end
end
