# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronFlightLineupTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY_WRITE = [{SessionCookie: []}, {Oauth2: ["fleet", "fleet:write"]}, {OpenId: ["fleet", "fleet:write"]}].freeze

  FLIGHT = "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/flights/{fleetSquadronFlightId}"
  SHIPS = "#{FLIGHT}/ships"
  SHIPS_SORT = "#{FLIGHT}/ships/sort"
  SHIP = "#{FLIGHT}/ships/{id}"
  SLOTS = "#{FLIGHT}/slots"
  SLOTS_SORT = "#{FLIGHT}/slots/sort"
  SLOT = "#{FLIGHT}/slots/{id}"
  CANDIDATES = "#{FLIGHT}/slots/{id}/candidates"

  FLIGHT_PARAMS = lambda do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"
    parameter name: "fleetSquadronFlightId", in: :path, schema: {type: :string, format: :uuid}, description: "Flight id"
  end

  api_path SHIPS do
    instance_exec(&FLIGHT_PARAMS)

    post("Add a ship to a Fleet Squadron Flight") do
      operationId "createFleetSquadronFlightShip"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::MissionShipCreateInput

      response(201, "created") do
        schema ::V1::Schemas::Fleets::Missions::MissionShip
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden - only whoever manages the roster arranges flights") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path SHIPS_SORT do
    instance_exec(&FLIGHT_PARAMS)

    put("Sort the ships of a Fleet Squadron Flight") do
      operationId "sortFleetSquadronFlightShips"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::SortInput

      response(200, "successful") do
        schema ::V1::Schemas::SuccessResponse
      end
    end
  end

  api_path SHIP do
    instance_exec(&FLIGHT_PARAMS)
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Ship id"

    put("Update a ship of a Fleet Squadron Flight") do
      operationId "updateFleetSquadronFlightShip"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::MissionShipUpdateInput

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Missions::MissionShip
      end
    end

    delete("Remove a ship from a Fleet Squadron Flight") do
      operationId "destroyFleetSquadronFlightShip"
      tags "FleetSquadrons"
      security SECURITY_WRITE

      response(204, "successful")
    end
  end

  api_path SLOTS do
    instance_exec(&FLIGHT_PARAMS)

    post("Add a slot to a Fleet Squadron Flight") do
      operationId "createFleetSquadronFlightSlot"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::MissionSlotCreateInput

      response(201, "created") do
        schema ::V1::Schemas::Fleets::Missions::MissionSlot
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found - a ship or team from elsewhere") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path SLOTS_SORT do
    instance_exec(&FLIGHT_PARAMS)

    put("Sort the slots of a Fleet Squadron Flight") do
      operationId "sortFleetSquadronFlightSlots"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::MissionSlotSortInput

      response(200, "successful") do
        schema ::V1::Schemas::SuccessResponse
      end
    end
  end

  api_path SLOT do
    instance_exec(&FLIGHT_PARAMS)
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Slot id"

    put("Update a slot of a Fleet Squadron Flight") do
      operationId "updateFleetSquadronFlightSlot"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::MissionSlotUpdateInput

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Missions::MissionSlot
      end
    end

    delete("Remove a slot from a Fleet Squadron Flight") do
      operationId "destroyFleetSquadronFlightSlot"
      tags "FleetSquadrons"
      security SECURITY_WRITE

      response(204, "successful")

      response(404, "not found - a slot of another flight") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path CANDIDATES do
    instance_exec(&FLIGHT_PARAMS)
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Slot id"

    put("Set who a Fleet Squadron Flight slot is meant for") do
      operationId "updateFleetSquadronFlightSlotCandidates"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronSlotCandidatesInput

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Missions::MissionSlot
      end

      response(400, "bad request - a ship the member does not give the squadron") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found - somebody outside the squadron") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @officer = create(:user)
    @pilot = create(:user)
    @wingman = create(:user)
    @fleet = create(:fleet, :with_squadrons, officers: [@officer], members: [@pilot, @wingman])
    @squadron = create(:fleet_squadron, fleet: @fleet, flights_enabled: true)
    @rows = [@pilot, @wingman].to_h do |user|
      [user, create(:fleet_squadron_membership, fleet_squadron: @squadron,
        fleet_membership: @fleet.fleet_memberships.kept.find_by!(user:))]
    end
    @flight = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    @team = @flight.team
  end

  def flight_params(**extra)
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug, fleetSquadronFlightId: @flight.id, **extra}
  end

  test "POST ships adds a member's ship to the flight, flown by its owner" do
    vehicle = create(:vehicle, user: @pilot, model: create(:model, :in_game))
    sign_in @officer

    assert_api_response :post, 201, api_path: SHIPS, path_params: flight_params, body: {vehicleId: vehicle.id} do
      ship = MissionShip.find(parsed_body["id"])
      assert_equal @team.id, ship.mission_team_id
      assert_equal vehicle.model_id, ship.model_id
      assert_equal vehicle.id, parsed_body.dig("vehicle", "id")
      assert_equal @pilot.username, parsed_body.dig("vehicle", "username")
    end

    pilot = MissionShip.find(parsed_body["id"]).mission_slots.find_by!(role: "pilot")
    assert_equal [@rows[@pilot].id], pilot.mission_slot_candidates.map(&:fleet_squadron_membership_id)
    assert_equal [vehicle.id], pilot.mission_slot_candidates.map(&:vehicle_id)
  end

  test "POST ships is refused to a plain member" do
    sign_in @pilot

    assert_api_response :post, 403, api_path: SHIPS, path_params: flight_params,
      body: {vehicleId: create(:vehicle, user: @pilot).id}
  end

  test "POST ships refuses a ship that names no member's ship" do
    sign_in @officer

    assert_api_response :post, 400, api_path: SHIPS, path_params: flight_params, body: {classification: "Combat"}
  end

  test "POST ships refuses a ship its owner does not give the squadron" do
    @rows[@pilot].update!(ships_filter: "picked")
    sign_in @officer

    assert_api_response :post, 400, api_path: SHIPS, path_params: flight_params,
      body: {vehicleId: create(:vehicle, user: @pilot, model: create(:model, :in_game)).id}
  end

  test "POST ships refuses a ship the flight already has" do
    ship = create(:mission_ship, mission_team: @team)
    sign_in @officer

    assert_api_response :post, 400, api_path: SHIPS, path_params: flight_params, body: {vehicleId: ship.vehicle_id}
  end

  test "PUT ships/sort orders the lineup" do
    first = create(:mission_ship, mission_team: @team, position: 0)
    second = create(:mission_ship, mission_team: @team, position: 1)
    sign_in @officer

    assert_api_response :put, 200, api_path: SHIPS_SORT, path_params: flight_params, body: {sorting: [second.id, first.id]}
    assert_equal [second.id, first.id], @team.mission_ships.reload.map(&:id)
  end

  test "PUT ships updates and DELETE removes a ship" do
    ship = create(:mission_ship, mission_team: @team)
    other = create(:mission_ship, mission_team: @team)
    sign_in @officer

    assert_api_response :put, 200, api_path: SHIP, path_params: flight_params(id: ship.id), body: {title: "Lead bomber"}
    assert_api_response :delete, 204, api_path: SHIP, path_params: flight_params(id: other.id)
    assert_equal ["Lead bomber"], @team.mission_ships.reload.map(&:title)
  end

  test "POST slots adds a slot to the team and to a ship" do
    ship = create(:mission_ship, mission_team: @team)
    sign_in @officer

    assert_api_response :post, 201, api_path: SLOTS, path_params: flight_params, body: {slottableType: "MissionTeam", slottableId: @team.id, title: "Lead"}
    assert_api_response :post, 201, api_path: SLOTS, path_params: flight_params, body: {slottableType: "MissionShip", slottableId: ship.id, title: "Pilot"}
  end

  test "POST slots is not found for a ship of a template" do
    template_ship = create(:mission_ship, mission_team: create(:mission_team, mission: create(:mission, fleet: @fleet)))
    sign_in @officer

    assert_api_response :post, 404, api_path: SLOTS, path_params: flight_params, body: {slottableType: "MissionShip", slottableId: template_ship.id, title: "Pilot"}
  end

  test "PUT slots/sort orders the slots" do
    first = create(:mission_slot, slottable: @team, position: 0)
    second = create(:mission_slot, slottable: @team, position: 1)
    sign_in @officer

    assert_api_response :put, 200, api_path: SLOTS_SORT, path_params: flight_params,
      body: {slottableType: "MissionTeam", slottableId: @team.id, sorting: [second.id, first.id]}
    assert_equal [second.id, first.id], @team.mission_slots.reload.reject(&:lead?).map(&:id)
  end

  test "PUT and DELETE a slot" do
    slot = create(:mission_slot, slottable: @team)
    sign_in @officer

    assert_api_response :put, 200, api_path: SLOT, path_params: flight_params(id: slot.id), body: {title: "Wing"}
    assert_api_response :delete, 204, api_path: SLOT, path_params: flight_params(id: slot.id)
  end

  test "DELETE is not found for a slot of another flight" do
    other = create(:mission_slot, slottable: create(:fleet_squadron_flight, fleet_squadron: @squadron).team)
    sign_in @officer

    assert_api_response :delete, 404, api_path: SLOT, path_params: flight_params(id: other.id)
  end

  test "PUT candidates lists the primary and alternates with the primary's ship" do
    slot = create(:mission_slot, slottable: @team)
    vehicle = create(:vehicle, user: @pilot)
    FleetVehicle.find_or_create_by!(fleet: @fleet, vehicle:)
    sign_in @officer

    assert_api_response :put, 200, api_path: CANDIDATES, path_params: flight_params(id: slot.id),
      body: {candidates: [{username: @pilot.username, vehicleId: vehicle.id}, {username: @wingman.username}]} do
      assert_equal [@pilot.username, @wingman.username], parsed_body["candidates"].map { |c| c["username"] }
      assert_equal vehicle.id, parsed_body["candidates"].first.dig("vehicle", "id")
    end
  end

  test "PUT candidates refuses a ship the member does not give the squadron" do
    slot = create(:mission_slot, slottable: @team)
    vehicle = create(:vehicle, user: @pilot)
    FleetVehicle.find_or_create_by!(fleet: @fleet, vehicle:)
    @rows[@pilot].update!(ships_filter: :picked)
    sign_in @officer

    assert_api_response :put, 400, api_path: CANDIDATES, path_params: flight_params(id: slot.id),
      body: {candidates: [{username: @pilot.username, vehicleId: vehicle.id}]}
  end

  test "PUT candidates is not found for somebody outside the squadron" do
    slot = create(:mission_slot, slottable: @team)
    sign_in @officer

    assert_api_response :put, 404, api_path: CANDIDATES, path_params: flight_params(id: slot.id), body: {candidates: [{username: @officer.username}]}
  end

  test "PUT candidates is refused to a plain member" do
    slot = create(:mission_slot, slottable: @team)
    sign_in @pilot

    assert_api_response :put, 403, api_path: CANDIDATES, path_params: flight_params(id: slot.id), body: {candidates: [{username: @pilot.username}]}
  end
  test "PUT candidates lists a member named twice once" do
    slot = create(:mission_slot, slottable: @team)
    sign_in @officer

    assert_api_response :put, 200, api_path: CANDIDATES, path_params: flight_params(id: slot.id),
      body: {candidates: [{username: @pilot.username}, {username: @pilot.username.upcase}, {username: @wingman.username}]} do
      assert_equal [@pilot.username, @wingman.username], parsed_body["candidates"].map { |c| c["username"] }
    end
  end
  test "DELETE refuses the flight's lead seat" do
    lead = @team.mission_slots.find_by!(lead: true)
    sign_in @officer

    delete "/api/v1/fleets/#{@fleet.slug}/squadrons/#{@squadron.slug}/flights/#{@flight.id}/slots/#{lead.id}", as: :json

    assert_response :bad_request
    assert MissionSlot.exists?(lead.id)
  end
end
