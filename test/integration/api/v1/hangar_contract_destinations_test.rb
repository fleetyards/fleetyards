# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarContractDestinationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/contract-destinations" do
    get("Hangar Contract Destinations") do
      operationId "hangarContractDestinations"
      tags "HangarInventoryTransfers"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Contracts::ContractDeliveryTargetsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_contracts")
    Flipper.enable("inventory_transfers")
    Flipper.enable("hangar_inventories")
    Flipper.enable("fleet_logistics")

    @author = create(:user)
    @contractor = create(:user)
    @fleet = create(:fleet, members: [@author, @contractor])
  end

  test "lists the destinations of the contracts the caller is working" do
    working = contract(:in_progress, crew: @contractor)
    fleet_bound = create(:fleet_contract, :in_progress, fleet: @fleet, created_by: @author)
    fleet_bound.fleet_contract_assignments.create!(user: @contractor, role: :crew,
      aasm_state: "accepted", accepted_at: Time.current)
    sign_in @contractor

    assert_api_response :get, 200 do
      assert_equal [working.id, fleet_bound.id], parsed_body.pluck("contractId")

      hangar = parsed_body.first

      assert_equal working.destination_inventory_id, hangar["destination"]["id"]
      assert_equal "user", hangar["destination"]["holder"]
      assert_equal @fleet.slug, hangar["fleetSlug"]
      assert_equal "fleet", parsed_body.second["destination"]["holder"]
    end
  end

  test "leaves out contracts the caller is not working, or that are not being worked" do
    contract(:in_progress)
    contract(:published)
    requested = contract(:in_progress)
    requested.fleet_contract_assignments.create!(user: @contractor, role: :crew, aasm_state: "requested")
    finished = contract(:in_progress, crew: @contractor)
    finished.update!(aasm_state: "fulfilled")
    sign_in @contractor

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "leaves out a fleet destination while the fleet's logistics are off" do
    Flipper.disable("fleet_logistics")
    hangar = contract(:in_progress, crew: @contractor)
    fleet_bound = create(:fleet_contract, :in_progress, fleet: @fleet, created_by: @author)
    fleet_bound.fleet_contract_assignments.create!(user: @contractor, role: :lead,
      aasm_state: "accepted", accepted_at: Time.current)
    sign_in @contractor

    assert_api_response :get, 200 do
      assert_equal [hangar.id], parsed_body.pluck("contractId")
    end
  end

  test "leaves out a hangar destination whose author has no hangar inventories" do
    contract(:in_progress, crew: @contractor)
    Flipper.disable("hangar_inventories")
    Flipper.enable_actor("hangar_inventories", @contractor)
    sign_in @contractor

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  # The author working their own contract delivers into it directly.
  test "leaves out a destination the caller holds" do
    contract(:in_progress, crew: @author)
    sign_in @author

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "leaves out contracts of a fleet the caller has left" do
    contract(:in_progress, crew: @contractor)
    @fleet.fleet_memberships.find_by(user: @contractor).destroy!
    sign_in @contractor

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "it needs a signed-in user" do
    assert_api_response :get, 401
  end

  private def contract(state, crew: nil)
    contract = create(:fleet_contract, state, :hangar_destination, fleet: @fleet, created_by: @author)
    return contract if crew.blank?

    contract.fleet_contract_assignments.create!(user: crew, role: :lead,
      aasm_state: "accepted", accepted_at: Time.current)
    contract
  end
end
