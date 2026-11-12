# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronShipSelectionShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/my-ships" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Which of my ships a Fleet Squadron gets") do
      operationId "fleetSquadronShipSelection"
      tags "FleetSquadrons"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronShipSelection
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
    @vehicle = create(:vehicle, user: @member)
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug}
  end

  test "GET my-ships returns the member's selection" do
    @row.update!(ships_filter: :picked)
    @row.fleet_squadron_membership_vehicles.create!(vehicle: @vehicle)
    sign_in @member

    assert_api_response :get, 200, path_params: path_params do
      assert_equal "picked", parsed_body["shipsFilter"]
      assert_nil parsed_body["hangarGroupId"]
      assert_equal [@vehicle.id], parsed_body["vehicleIds"]
    end
  end

  test "GET my-ships is not found outside the squadron" do
    sign_in @outsider

    assert_api_response :get, 404, path_params: path_params
  end

  test "GET my-ships needs a session" do
    assert_api_response :get, 401, path_params: path_params
  end
end
