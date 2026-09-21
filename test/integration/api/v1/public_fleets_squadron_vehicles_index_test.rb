# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsSquadronVehiclesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Public Fleet Squadron Vehicles List") do
      operationId "publicFleetSquadronVehicles"
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

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetVehicles
      end

      response(404, "not found unless the fleet is public") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Sidekiq::Testing.inline!
    Flipper.enable("fleet_squadrons")
    @owner = create(:user, vehicle_count: 2)
    @member = create(:user, vehicle_count: 3)
    @fleet = create(:fleet, admins: [@owner], members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership)
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "a public squadron's ships are readable by anybody" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "a private fleet's squadron ships are not readable" do
    private_fleet = create(:fleet, :private, admins: [create(:user)])
    squadron = create(:fleet_squadron, fleet: private_fleet)

    assert_api_response :get, 404,
      path_params: {fleetSlug: private_fleet.slug, fleetSquadronSlug: squadron.slug}
  end

  test "an unknown squadron is not found" do
    assert_api_response :get, 404,
      path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: "no-such-wing"}
  end
end
