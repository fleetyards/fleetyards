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

  test "restoring an archived mission needs delete access, not just update" do
    updater = create(:user)
    role = @fleet.fleet_roles.create!(
      name: "Mission editor", rank: 90,
      resource_access: ["fleet:missions:read", "fleet:missions:update"]
    )
    create(:fleet_membership, fleet: @fleet, user: updater,
      fleet_role: role, aasm_state: :accepted)
    mission = create(:mission, fleet: @fleet, created_by: @admin,
      archived_at: 1.day.ago)
    Flipper.enable_actor("fleet_mission_builder", @fleet)

    sign_in updater
    put "/api/v1/fleets/#{@fleet.slug}/missions/#{mission.slug}/unarchive"

    assert_response :forbidden
    assert_not_nil mission.reload.archived_at
  end

  test "an update cannot clear archived_at on its own" do
    mission = create(:mission, fleet: @fleet, created_by: @admin,
      archived_at: 1.day.ago)
    Flipper.enable_actor("fleet_mission_builder", @fleet)

    patch "/api/v1/fleets/#{@fleet.slug}/missions/#{mission.slug}",
      params: {archivedAt: nil}, as: :json

    assert_response :success
    assert_not_nil mission.reload.archived_at
  end
end
