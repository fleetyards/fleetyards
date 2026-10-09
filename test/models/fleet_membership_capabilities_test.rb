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

  test "renaming squadron ranks needs the squadrons manage privilege" do
    assert membership_with(["fleet:squadrons:manage"]).capabilities[:manage_squadrons]
    refute membership_with(["fleet:squadrons:members:manage"]).capabilities[:manage_squadrons]
    assert_equal FleetSquadron::MANAGE_PRIVILEGES, FleetMembership::CAPABILITY_PRIVILEGES[:manage_squadrons]
  end

  # The switch is a fleet attribute, so it follows FleetPolicy#params_filter
  # rather than the squadron privileges.
  test "switching squadrons on needs the fleet update privilege" do
    assert membership_with(["fleet:update"]).capabilities[:enable_squadrons]
    refute membership_with(["fleet:squadrons:manage"]).capabilities[:enable_squadrons]
  end

  test "renaming roles follows FleetRolePolicy" do
    assert membership_with(["fleet:roles:update"]).capabilities[:update_roles]
    refute membership_with(["fleet:roles:read"]).capabilities[:update_roles]
    assert_equal FleetRolePolicy::UPDATE_PRIVILEGES, FleetMembership::CAPABILITY_PRIVILEGES[:update_roles]
  end

  test "reading contracts follows FleetContractPolicy" do
    assert membership_with(["fleet:contracts:read"]).capabilities[:read_contracts]
    refute membership_with(["fleet:missions:read"]).capabilities[:read_contracts]
    assert_equal FleetContractPolicy::READ, FleetMembership::CAPABILITY_PRIVILEGES[:read_contracts]
  end

  test "reading events follows FleetEventPolicy" do
    [["fleet:events:read"], ["fleet:events:manage"], ["fleet:missions:read"], []].each do |access|
      membership = membership_with(access)
      membership.update!(aasm_state: :accepted)
      allowed = FleetEventPolicy.new(user: membership.user, fleet: @fleet).apply(:index?)

      assert_equal allowed, membership.capabilities[:read_events], "for #{access.inspect}"
    end
  end

  test "capability keys mirror CAPABILITY_PRIVILEGES" do
    assert_equal FleetMembership::CAPABILITY_PRIVILEGES.keys.sort,
      membership_with([]).capabilities.keys.sort
  end
end
