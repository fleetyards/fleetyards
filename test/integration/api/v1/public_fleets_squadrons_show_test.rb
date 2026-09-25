# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsSquadronsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/squadrons/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Public Fleet Squadron") do
      operationId "publicFleetSquadron"
      tags "FleetSquadrons"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::PublicFleetSquadron
      end

      response(404, "not found unless the fleet is public") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @fleet = create(:fleet, :with_squadrons, admins: [create(:user)])
    @squadron = create(:fleet_squadron, fleet: @fleet, name: "Combat Wing")
  end

  test "a public fleet's squadron is readable by anybody" do
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug} do
      assert_equal "Combat Wing", parsed_body["name"]
    end
  end

  test "a private fleet's squadron is not readable" do
    private_fleet = create(:fleet, :private, admins: [create(:user)])
    squadron = create(:fleet_squadron, fleet: private_fleet)

    assert_api_response :get, 404, path_params: {fleetSlug: private_fleet.slug, slug: squadron.slug}
  end

  test "an unknown squadron is not found" do
    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, slug: "no-such-wing"}
  end
end
