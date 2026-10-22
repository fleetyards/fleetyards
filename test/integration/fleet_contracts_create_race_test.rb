# frozen_string_literal: true

require "test_helper"

# Lives outside test/integration/api/v1 on purpose: it asserts behaviour under a
# concurrent insert rather than a documented response, so it must not contribute
# to the generated OpenAPI schema.
class FleetContractsCreateRaceTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("fleet_contracts")
    Flipper.enable("fleet_logistics")

    @officer = create(:user)
    @fleet = create(:fleet, admins: [@officer])
    @depot = create(:fleet_inventory, fleet: @fleet)
    create(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @depot, title: "Get Iron")
    sign_in @officer
  end

  test "a title whose slug another request just took answers 400 rather than 500" do
    # The slug check is a read, so a request whose validation ran before the
    # winner's row landed reaches the insert regardless.
    FleetContract.any_instance.stubs(:valid?).returns(true)

    assert_no_difference -> { @fleet.fleet_contracts.count } do
      post "/api/v1/fleets/#{@fleet.slug}/contracts",
        params: {title: "Get Iron!", kind: "procurement", destinationFleetInventoryId: @depot.id},
        as: :json
    end

    assert_equal 400, response.status
    assert_equal "validation_error.fleet_contracts.create", response.parsed_body["code"]
  end
end
