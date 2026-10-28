# frozen_string_literal: true

require "test_helper"

class FleetMembershipBroadcastTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, created_by: @admin.id, members: [@member])
    @membership = @fleet.fleet_memberships.find_by(user_id: @member.id)

    @invited = create(:user)
    @fleet.fleet_memberships.create!(user: @invited, fleet_role: @fleet.default_member_role).invite!
    @requester = create(:user)
    @fleet.fleet_memberships.create!(user: @requester, fleet_role: @fleet.default_member_role).request!
  end

  test "a roster change reaches accepted members, not invited or pending ones" do
    recipients = []
    FleetMembersChannel.stubs(:broadcast_to).with { |user, _| recipients << user.id }

    @membership.update!(fleet_role: @fleet.fleet_roles.ranked.second)

    assert_includes recipients, @admin.id
    assert_includes recipients, @member.id
    assert_not_includes recipients, @invited.id
    assert_not_includes recipients, @requester.id
  end

  test "a removed member's roster update goes only to members who may read the roster" do
    @fleet.default_member_role.update!(resource_access: [])
    recipients = []
    FleetMembersChannel.stubs(:broadcast_to).with { |user, _| recipients << user.id }
    FleetVehiclesChannel.stubs(:broadcast_to)

    @membership.destroy!

    assert_equal [@admin.id], recipients.uniq
  end
end
