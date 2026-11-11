# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronShipRequestsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY_READ = [
    {SessionCookie: []},
    {Oauth2: ["fleet", "fleet:read"]},
    {OpenId: ["fleet", "fleet:read"]}
  ].freeze

  SECURITY_WRITE = [
    {SessionCookie: []},
    {Oauth2: ["fleet", "fleet:write"]},
    {OpenId: ["fleet", "fleet:write"]}
  ].freeze

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/ship-requests" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Fleet Squadron Ship Requests") do
      operationId "fleetSquadronShipRequests"
      tags "FleetSquadrons"
      produces "application/json"
      security SECURITY_READ

      response(200, "successful - every open request for the roster's managers, a member's own otherwise") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronShipRequestsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - neither in the squadron nor managing it") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    post("Ask a member of a Fleet Squadron for a ship") do
      operationId "createFleetSquadronShipRequest"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronShipRequestCreateInput

      response(201, "created") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronShipRequest
      end

      response(400, "bad request - the ship is not the member's, not in the fleet or already given") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - only whoever manages the roster asks for ships") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found - the member is not in this squadron") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/ship-requests/{id}/accept" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Request id"

    put("Accept a Fleet Squadron Ship Request") do
      operationId "acceptFleetSquadronShipRequest"
      tags "FleetSquadrons"
      produces "application/json"
      security SECURITY_WRITE

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - only the member whose ship it is answers") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/ship-requests/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Request id"

    delete("Decline or withdraw a Fleet Squadron Ship Request") do
      operationId "destroyFleetSquadronShipRequest"
      tags "FleetSquadrons"
      produces "application/json"
      security SECURITY_WRITE

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @officer = create(:user)
    @pilot = create(:user)
    @other = create(:user)
    @fleet = create(:fleet, :with_squadrons, officers: [@officer], members: [@pilot, @other])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @row = create(:fleet_squadron_membership, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.kept.find_by!(user: @pilot))
    @other_row = create(:fleet_squadron_membership, fleet_squadron: create(:fleet_squadron, fleet: @fleet, team: true),
      fleet_membership: @fleet.fleet_memberships.kept.find_by!(user: @other))
    @vehicle = create(:vehicle, user: @pilot)
    FleetVehicle.find_or_create_by!(fleet: @fleet, vehicle: @vehicle)
    @row.update!(ships_filter: :picked)
  end

  def collection_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug}
  end

  def request_params(request)
    collection_params.merge(id: request.id)
  end

  def open_request
    create(:fleet_squadron_ship_request, fleet_squadron_membership: @row, vehicle: @vehicle,
      requested_by: @fleet.fleet_memberships.find_by!(user: @officer))
  end

  test "POST asks the member for a ship and tells them" do
    sign_in @officer

    assert_difference -> { Notification.where(user: @pilot, notification_type: "fleet_squadron_ship_request_received").count }, 1 do
      assert_api_response :post, 201, path_params: collection_params,
        body: {username: @pilot.username, vehicleId: @vehicle.id} do
        assert_equal @vehicle.id, parsed_body.dig("vehicle", "id")
        assert_equal @officer.username, parsed_body["requestedByUsername"]
      end
    end
  end

  test "POST refuses a ship the squadron already gets" do
    @row.update!(ships_filter: :all)
    sign_in @officer

    assert_api_response :post, 400, path_params: collection_params,
      body: {username: @pilot.username, vehicleId: @vehicle.id}
  end

  test "POST refuses a ship the fleet cannot see" do
    hidden = create(:vehicle, user: @pilot)
    FleetVehicle.where(vehicle: hidden).delete_all
    sign_in @officer

    assert_api_response :post, 400, path_params: collection_params,
      body: {username: @pilot.username, vehicleId: hidden.id}
  end

  test "POST is not found for somebody outside the squadron" do
    sign_in @officer

    assert_api_response :post, 404, path_params: collection_params,
      body: {username: @other.username, vehicleId: create(:vehicle, user: @other).id}
  end

  test "POST is refused to a plain member" do
    sign_in @pilot

    assert_api_response :post, 403, path_params: collection_params,
      body: {username: @pilot.username, vehicleId: @vehicle.id}
  end

  test "GET lists the member's own requests and everything for the officer" do
    open_request
    other_vehicle = create(:vehicle, user: @other)
    FleetVehicle.find_or_create_by!(fleet: @fleet, vehicle: other_vehicle)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @other_row.fleet_membership)
      .update!(ships_filter: :picked)
    create(:fleet_squadron_ship_request,
      fleet_squadron_membership: @squadron.fleet_squadron_memberships.find_by!(fleet_membership: @other_row.fleet_membership),
      vehicle: other_vehicle)

    sign_in @pilot
    assert_api_response :get, 200, path_params: collection_params do
      assert_equal [@pilot.username], parsed_body.map { |request| request.dig("member", "username") }
    end

    sign_in @officer
    assert_api_response :get, 200, path_params: collection_params do
      assert_equal 2, parsed_body.size
    end
  end

  test "GET is refused to somebody neither in nor managing the squadron" do
    sign_in @other

    assert_api_response :get, 403, path_params: collection_params
  end

  test "GET needs a session" do
    assert_api_response :get, 401, path_params: collection_params
  end

  test "PUT accept adds the ship to the member's picks and tells the officer" do
    request = open_request
    sign_in @pilot

    assert_difference -> { Notification.where(user: @officer, notification_type: "fleet_squadron_ship_request_accepted").count }, 1 do
      assert_api_response :put, 204, path_params: request_params(request)
    end

    assert_equal [@vehicle.id], @row.fleet_squadron_membership_vehicles.map(&:vehicle_id)
    assert_not FleetSquadronShipRequest.exists?(request.id)
  end

  test "PUT accept is the member's alone" do
    request = open_request
    sign_in @officer

    assert_api_response :put, 403, path_params: request_params(request)
  end

  test "PUT accept needs a session" do
    assert_api_response :put, 401, path_params: request_params(open_request)
  end

  test "DELETE lets the member decline" do
    request = open_request
    sign_in @pilot

    assert_api_response :delete, 204, path_params: request_params(request)
    assert_empty @row.fleet_squadron_membership_vehicles
  end

  test "DELETE lets the officer withdraw" do
    request = open_request
    sign_in @officer

    assert_api_response :delete, 204, path_params: request_params(request)
  end

  test "DELETE is refused to another member" do
    request = open_request
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @other_row.fleet_membership)
    sign_in @other

    assert_api_response :delete, 403, path_params: request_params(request)
  end

  test "DELETE is not found for a request elsewhere" do
    sign_in @pilot

    assert_api_response :delete, 404, path_params: collection_params.merge(id: SecureRandom.uuid)
  end
end
