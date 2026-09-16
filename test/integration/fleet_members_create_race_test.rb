# frozen_string_literal: true

require "test_helper"

# Lives outside test/integration/api/v1 on purpose: it asserts behaviour under a
# concurrent insert rather than a documented response, so it must not contribute
# to the generated OpenAPI schema.
class FleetMembersCreateRaceTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    sign_in @admin
  end

  test "adding a member another request just added answers 400 rather than 500" do
    # The uniqueness validation is a read, so a request whose validation ran
    # before the winner's row landed reaches the insert regardless.
    FleetMembership.any_instance.stubs(:valid?).returns(true)

    assert_no_difference -> { FleetMembership.kept.where(fleet: @fleet).count } do
      post "/api/v1/fleets/#{@fleet.slug}/members",
        params: {username: @member.username},
        as: :json
    end

    assert_equal 400, response.status
    assert_equal "validation_error.fleet_members.create", JSON.parse(response.body)["code"]

    # `invite!` runs only on a successful save, so the loser must not have
    # notified anyone.
    assert_nil Notification.find_by(user: @member, notification_type: "fleet_invite")
  end
end
