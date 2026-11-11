# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronShipSelectionUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/my-ships" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    put("Choose which of my ships a Fleet Squadron gets") do
      operationId "updateFleetSquadronShipSelection"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronShipSelectionInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronShipSelection
      end

      response(400, "bad request - a hangar group or ship that is not the member's") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found - the reader is not in this squadron") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @member = create(:user)
    @outsider = create(:user)
    @fleet = create(:fleet, :with_squadrons, members: [@member, @outsider])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @row = create(:fleet_squadron_membership, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.kept.find_by!(user: @member))
    @first = create(:vehicle, user: @member)
    @second = create(:vehicle, user: @member)
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug}
  end

  test "PUT my-ships picks ships" do
    sign_in @member

    assert_api_response :put, 200, path_params: path_params,
      body: {shipsFilter: "picked", vehicleIds: [@first.id]} do
      assert_equal "picked", parsed_body["shipsFilter"]
      assert_equal [@first.id], parsed_body["vehicleIds"]
    end
  end

  test "PUT my-ships replaces the picks with the list it is given" do
    @row.update!(ships_filter: :picked)
    @row.fleet_squadron_membership_vehicles.create!(vehicle: @first)
    sign_in @member

    assert_api_response :put, 200, path_params: path_params, body: {vehicleIds: [@second.id]} do
      assert_equal [@second.id], @row.fleet_squadron_membership_vehicles.reload.map(&:vehicle_id)
    end
  end

  test "PUT my-ships takes a hangar group of the member's and drops it when switching away" do
    group = create(:hangar_group, user: @member)
    sign_in @member

    assert_api_response :put, 200, path_params: path_params,
      body: {shipsFilter: "hangar_group", hangarGroupId: group.id} do
      assert_equal group.id, parsed_body["hangarGroupId"]
    end

    assert_api_response :put, 200, path_params: path_params, body: {shipsFilter: "all"} do
      assert_nil parsed_body["hangarGroupId"]
    end
  end

  test "PUT my-ships refuses somebody else's hangar group" do
    sign_in @member

    assert_api_response :put, 400, path_params: path_params,
      body: {shipsFilter: "hangar_group", hangarGroupId: create(:hangar_group).id}
  end

  test "PUT my-ships refuses somebody else's ship and keeps the picks" do
    @row.fleet_squadron_membership_vehicles.create!(vehicle: @first)
    sign_in @member

    assert_api_response :put, 400, path_params: path_params,
      body: {vehicleIds: [create(:vehicle).id]} do
      assert_equal [@first.id], @row.fleet_squadron_membership_vehicles.reload.map(&:vehicle_id)
    end
  end

  test "PUT my-ships is not found outside the squadron" do
    sign_in @outsider

    assert_api_response :put, 404, path_params: path_params, body: {shipsFilter: "all"}
  end

  test "PUT my-ships needs a session" do
    assert_api_response :put, 401, path_params: path_params, body: {shipsFilter: "all"}
  end
end
