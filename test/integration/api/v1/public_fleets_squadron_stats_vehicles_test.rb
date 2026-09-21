# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsSquadronStatsVehiclesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/stats/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Public Fleet Squadron Vehicles Stats") do
      operationId "publicFleetSquadronVehiclesStats"
      tags "FleetSquadrons"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/FleetVehiclesStats"
      end

      response(404, "not found unless the fleet publishes its stats") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Sidekiq::Testing.inline!
    Flipper.enable("fleet_squadrons")
    @owner = create(:user, vehicle_count: 2)
    @member = create(:user, vehicle_count: 3)
    @fleet = create(:fleet, :with_public_stats, admins: [@owner], members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership)
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "a squadron's numbers are readable when the fleet publishes its stats" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug} do
      assert_equal 3, parsed_body["total"]
    end
  end

  # The stats switch is its own: a fleet that is public but has not published
  # its numbers hands over neither its own nor a squadron's.
  test "a public fleet that has not published its stats hands over no squadron numbers" do
    quiet = create(:fleet, admins: [create(:user)])
    squadron = create(:fleet_squadron, fleet: quiet)

    assert_api_response :get, 404,
      path_params: {fleetSlug: quiet.slug, fleetSquadronSlug: squadron.slug}
  end

  test "an unknown squadron is not found" do
    assert_api_response :get, 404,
      path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: "no-such-wing"}
  end
end
