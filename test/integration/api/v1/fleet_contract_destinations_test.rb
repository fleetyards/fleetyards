# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetContractDestinationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/contract-destinations" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Fleet Contract Destinations") do
      operationId "fleetContractDestinations"
      tags "Contracts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::FleetContractDestinationsList
      end

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
    Flipper.enable("fleet_contracts")
    Flipper.enable("fleet_logistics")
    Flipper.enable("inventory_transfers")
    Flipper.enable("hangar_inventories")

    @officer = create(:user)
    @author = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@officer], members: [@member])
    create(:fleet_membership, fleet: @fleet, user: @author, aasm_state: :accepted,
      fleet_role: create(:fleet_role, fleet: @fleet, name: "Quartermaster",
        resource_access: FleetRole.preset_privileges[:member] + ["fleet:contracts:create"]))

    @depot = create(:fleet_inventory, fleet: @fleet, name: "Depot")
    @vault = create(:fleet_inventory, fleet: @fleet, name: "Vault", visibility: :officers_only)
  end

  test "an author without inventory rights is offered only their own inventories" do
    locker = create(:inventory, holder: @author)
    create(:inventory, holder: @member)
    sign_in @author

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal [locker.id], parsed_body.pluck("id")
      assert_equal ["user"], parsed_body.pluck("holder")
    end
  end

  test "an officer is offered the fleet's inventories and their own" do
    own = create(:inventory, holder: @officer)
    sign_in @officer

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal [@depot.id, @vault.id, own.id], parsed_body.pluck("id")
      assert_equal %w[fleet fleet user], parsed_body.pluck("holder")
    end
  end

  test "a member who cannot write contracts is refused" do
    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "an outsider cannot find the fleet" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug}
  end

  test "it needs a signed-in user" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
