# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsSquadronsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/squadrons" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Public Fleet Squadrons List") do
      operationId "publicFleetSquadrons"
      tags "FleetSquadrons"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::PublicFleetSquadronsList
      end

      response(404, "not found unless the fleet is public") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @owner = create(:user)
    @fleet = create(:fleet, admins: [@owner])
    @squadron = create(:fleet_squadron, :with_color, fleet: @fleet, name: "Combat Wing", description: "Kept back")
  end

  test "a public fleet's squadrons are readable by anybody" do
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["Combat Wing"], parsed_body["items"].map { |entry| entry["name"] }
      assert_equal "#ff8800", parsed_body["items"].first["color"]
    end
  end

  test "a public fleet's squadrons follow the order the fleet gave them" do
    zulu = create(:fleet_squadron, fleet: @fleet, name: "Zulu")
    alpha = create(:fleet_squadron, fleet: @fleet, name: "Alpha")
    zulu.update!(position: 0)
    alpha.update!(position: 1)
    @squadron.update!(position: 2)

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["Zulu", "Alpha", "Combat Wing"], parsed_body["items"].map { |entry| entry["name"] }
    end
  end

  # D7: the list and the sizes, never the people or the fleet's own notes on a
  # squadron. `additionalProperties: false` on the component is what enforces
  # the first half; this states the intent.
  test "a public squadron carries no description and no member identities" do
    membership = create(:fleet_membership, :accepted, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership)

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      entry = parsed_body["items"].first

      assert_equal 1, entry["memberCount"]
      refute entry.key?("description")
      refute entry.key?("members")
    end
  end

  test "a private fleet's squadrons are not readable" do
    private_fleet = create(:fleet, :private, admins: [create(:user)])
    create(:fleet_squadron, fleet: private_fleet)

    assert_api_response :get, 404, path_params: {fleetSlug: private_fleet.slug}
  end

  test "squadrons are not readable when fleet_squadrons is disabled" do
    Flipper.disable("fleet_squadrons")

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug}
  end

  test "an unknown fleet is not found" do
    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end
end
