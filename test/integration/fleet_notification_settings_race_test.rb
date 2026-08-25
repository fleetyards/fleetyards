# frozen_string_literal: true

require "test_helper"

# Lives outside test/integration/api/v1 on purpose: it asserts behaviour under a
# concurrent insert rather than a documented response, so it must not contribute
# to the generated OpenAPI schema.
class FleetNotificationSettingsRaceTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @fleet = create(:fleet, admins: [@user])
    sign_in @user
  end

  test "a settings row created by a concurrent request is reused" do
    FleetNotificationSetting.create!(fleet: @fleet)
    # Both requests miss the association and both try to insert; only one wins
    # against the unique index on fleet_id.
    Fleet.any_instance.stubs(:fleet_notification_setting).returns(nil)

    get "/api/v1/fleets/#{@fleet.slug}/notifications/discord-status"

    assert_response :success
    assert_equal 1, FleetNotificationSetting.where(fleet: @fleet).count
  end
end
