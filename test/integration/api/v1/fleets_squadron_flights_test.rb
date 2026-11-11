# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronFlightsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY_READ = [{SessionCookie: []}, {Oauth2: ["fleet", "fleet:read"]}, {OpenId: ["fleet", "fleet:read"]}].freeze
  SECURITY_WRITE = [{SessionCookie: []}, {Oauth2: ["fleet", "fleet:write"]}, {OpenId: ["fleet", "fleet:write"]}].freeze

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/flights" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Fleet Squadron Flights") do
      operationId "fleetSquadronFlights"
      tags "FleetSquadrons"
      produces "application/json"
      security SECURITY_READ

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronFlightsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    post("Create a Fleet Squadron Flight") do
      operationId "createFleetSquadronFlight"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronFlightInput

      response(201, "created") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronFlight
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - only whoever manages the roster arranges flights") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/flights/sort" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    put("Sort Fleet Squadron Flights") do
      operationId "sortFleetSquadronFlights"
      tags "FleetSquadrons"
      consumes "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::SortInput

      response(204, "successful")

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/flights/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Flight id"

    get("Fleet Squadron Flight") do
      operationId "fleetSquadronFlight"
      tags "FleetSquadrons"
      produces "application/json"
      security SECURITY_READ

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronFlight
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Update a Fleet Squadron Flight") do
      operationId "updateFleetSquadronFlight"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"
      security SECURITY_WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronFlightInput

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronFlight
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Destroy a Fleet Squadron Flight") do
      operationId "destroyFleetSquadronFlight"
      tags "FleetSquadrons"
      security SECURITY_WRITE

      response(204, "successful")

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @officer = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, :with_squadrons, officers: [@officer], members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
  end

  def collection_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug}
  end

  def flight_params(flight)
    collection_params.merge(id: flight.id)
  end

  test "POST creates a flight with an empty lineup" do
    sign_in @officer

    assert_api_response :post, 201, path_params: collection_params, body: {name: "Strike", description: "Two bombers"} do
      assert_equal "Strike", parsed_body["name"]
      assert_empty parsed_body["ships"]
      assert FleetSquadronFlight.find(parsed_body["id"]).mission_team.present?
    end
  end

  test "POST refuses a name the squadron already uses" do
    create(:fleet_squadron_flight, fleet_squadron: @squadron, name: "Strike")
    sign_in @officer

    assert_api_response :post, 400, path_params: collection_params, body: {name: "strike"}
  end

  test "POST is refused to a plain member" do
    sign_in @member

    assert_api_response :post, 403, path_params: collection_params, body: {name: "Strike"}
  end

  test "POST needs a session" do
    assert_api_response :post, 401, path_params: collection_params, body: {name: "Strike"}
  end

  test "GET lists the squadron's flights for a member" do
    flight = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    create(:mission_slot, slottable: flight.team, title: "Comms")
    sign_in @member

    assert_api_response :get, 200, path_params: collection_params do
      assert_equal [flight.id], parsed_body.map { |row| row["id"] }
      assert_equal [["Flight lead", true], ["Comms", false]], parsed_body.first["slots"].map { |slot| [slot["title"], slot["lead"]] }
    end
  end

  test "GET needs a session" do
    assert_api_response :get, 401, path_params: collection_params
  end

  test "GET is not found for another fleet's squadron" do
    sign_in @member

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: "nope"}
  end

  test "GET one flight" do
    flight = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    sign_in @member

    assert_api_response :get, 200, path_params: flight_params(flight)
  end

  test "GET one flight is not found in another squadron" do
    flight = create(:fleet_squadron_flight, fleet_squadron: create(:fleet_squadron, fleet: @fleet))
    sign_in @member

    assert_api_response :get, 404, path_params: flight_params(flight)
  end

  test "PUT renames a flight" do
    flight = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    sign_in @officer

    assert_api_response :put, 200, path_params: flight_params(flight), body: {name: "Escort"} do
      assert_equal "Escort", parsed_body["name"]
    end
  end

  test "PUT refuses a blank name" do
    flight = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    sign_in @officer

    assert_api_response :put, 400, path_params: flight_params(flight), body: {name: ""}
  end

  test "PUT is refused to a plain member" do
    flight = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    sign_in @member

    assert_api_response :put, 403, path_params: flight_params(flight), body: {name: "Escort"}
  end

  test "DELETE removes the flight and its lineup" do
    flight = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    team_id = flight.team.id
    sign_in @officer

    assert_api_response :delete, 204, path_params: flight_params(flight)
    assert_not MissionTeam.exists?(team_id)
  end

  test "DELETE is refused to a plain member" do
    flight = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    sign_in @member

    assert_api_response :delete, 403, path_params: flight_params(flight)
  end

  test "PUT sort orders the flights" do
    first = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    second = create(:fleet_squadron_flight, fleet_squadron: @squadron)
    sign_in @officer

    assert_api_response :put, 204, path_params: collection_params, body: {sorting: [second.id, first.id]}
    assert_equal [second.id, first.id], @squadron.fleet_squadron_flights.reload.map(&:id)
  end

  test "PUT sort is refused to a plain member" do
    sign_in @member

    assert_api_response :put, 403, path_params: collection_params, body: {sorting: []}
  end
end
