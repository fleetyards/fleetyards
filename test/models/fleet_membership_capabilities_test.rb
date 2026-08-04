# frozen_string_literal: true

require "test_helper"

class FleetMembershipCapabilitiesTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
  end

  def membership_with(resource_access)
    role = create(:fleet_role, fleet: @fleet,
      name: "Capability Test #{resource_access.join("-").presence || "none"}",
      resource_access: resource_access)
    create(:fleet_membership, fleet: @fleet, fleet_role: role)
  end

  test "no privileges grants no capabilities" do
    capabilities = membership_with([]).capabilities

    assert capabilities.values.none?, "expected every capability to be false"
  end

  test "fleet:manage grants every capability" do
    capabilities = membership_with(["fleet:manage"]).capabilities

    assert capabilities.values.all?, "expected every capability to be true"
  end

  test "a group manage privilege grants that group's capabilities" do
    capabilities = membership_with(["fleet:memberships:manage"]).capabilities

    assert capabilities[:read_members]
    assert capabilities[:create_members]
    assert capabilities[:update_members]
    assert capabilities[:destroy_members]
    refute capabilities[:read_inventories]
    refute capabilities[:manage_fleet]
  end

  test "a specific privilege grants only its capability" do
    capabilities = membership_with(["fleet:inventories:read"]).capabilities

    assert capabilities[:read_inventories]
    refute capabilities[:create_inventories]
    refute capabilities[:read_members]
  end

  test "capability keys mirror CAPABILITY_PRIVILEGES" do
    assert_equal FleetMembership::CAPABILITY_PRIVILEGES.keys.sort,
      membership_with([]).capabilities.keys.sort
  end
end
