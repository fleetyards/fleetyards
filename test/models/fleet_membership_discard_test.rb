# frozen_string_literal: true

require "test_helper"

class FleetMembershipDiscardTest < ActiveSupport::TestCase
  setup do
    @creator = create(:user)
    @member = create(:user)
  end

  test "discarding a membership with a permanent role is blocked" do
    fleet = create(:fleet, created_by: @creator.id)
    admin_membership = fleet.fleet_memberships.find_by(user_id: @creator.id)

    assert admin_membership.fleet_role.permanent?
    assert_not admin_membership.discard
    assert admin_membership.reload.kept?
  end

  test "a discarded membership is hidden from the fleet's kept members" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    membership = fleet.fleet_memberships.find_by(user_id: @member.id)

    assert membership.discard

    assert_not fleet.fleet_memberships.kept.exists?(user_id: @member.id)
  end

  test "a user can rejoin a fleet after their membership was discarded" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    fleet.fleet_memberships.find_by(user_id: @member.id).discard

    rejoined = fleet.fleet_memberships.build(user: @member, fleet_role: fleet.default_member_role)

    assert rejoined.valid?, rejoined.errors.full_messages.to_sentence
    assert rejoined.save
  end
end
