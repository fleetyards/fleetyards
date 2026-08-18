# frozen_string_literal: true

require "test_helper"

# Lives outside test/integration/api/v1 on purpose: it asserts gate behaviour
# rather than a documented response, so it must not contribute to the generated
# OpenAPI schema.
class FleetMissionBuilderGateTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    sign_in @admin
  end

  test "the missions list is forbidden while the flag is off" do
    get "/api/v1/fleets/#{@fleet.slug}/missions"

    assert_response :forbidden
  end

  test "enabling the flag for the fleet opens the missions list" do
    Flipper.enable_actor("fleet_mission_builder", @fleet)

    get "/api/v1/fleets/#{@fleet.slug}/missions"

    assert_response :success
  end

  test "a flag enabled for one fleet does not open another" do
    other = create(:fleet, admins: [@admin])
    Flipper.enable_actor("fleet_mission_builder", other)

    get "/api/v1/fleets/#{@fleet.slug}/missions"

    assert_response :forbidden
  end

  test "enabling the flag for the member alone still opens the list" do
    Flipper.enable_actor("fleet_mission_builder", @admin)

    get "/api/v1/fleets/#{@fleet.slug}/missions"

    assert_response :success
  end

  test "the events list is forbidden while the flag is off" do
    get "/api/v1/fleets/#{@fleet.slug}/events"

    assert_response :forbidden
  end

  test "enabling the flag for the fleet opens the events list" do
    Flipper.enable_actor("fleet_mission_builder", @fleet)

    get "/api/v1/fleets/#{@fleet.slug}/events"

    assert_response :success
  end
end
