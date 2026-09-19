# frozen_string_literal: true

require "test_helper"

# The trap this covers: the rule is stated twice -- once in Ruby by
# `FleetInventory#visible_to?` for a single record, once in SQL by the policy's
# relation scope for a list. A change to one that misses the other opens an
# officers-only store on every list endpoint while `show` keeps refusing it, or
# hides it from a list the show endpoint still serves.
class FleetInventoryPolicyTest < ActiveSupport::TestCase
  setup do
    @officer = create(:user)
    @member = create(:user)
    @manager = create(:user)
    @stranger = create(:user)
    @fleet = create(:fleet, officers: [@officer], members: [@member, @manager])

    @open = create(:fleet_inventory, fleet: @fleet)
    @closed = create(:fleet_inventory, :officers_only, fleet: @fleet)
    @managed = create(:fleet_inventory, :officers_only, fleet: @fleet, manager: @manager)
  end

  def policy_for(reader, record = nil)
    FleetInventoryPolicy.new(record, user: reader, fleet: @fleet)
  end

  def scoped(reader, name = :default)
    policy_for(reader)
      .apply_scope(FleetInventory.where(fleet: @fleet), type: :active_record_relation, name: name)
      .to_a
  end

  def member_with(privileges)
    role = create(:fleet_role, fleet: @fleet,
      name: "Policy Test #{privileges.join("-").presence || "none"}",
      resource_access: privileges)
    create(:user).tap do |user|
      create(:fleet_membership, :accepted, fleet: @fleet, user: user, fleet_role: role)
    end
  end

  test "the relation scope and the record check agree for every reader" do
    [@officer, @member, @manager, @stranger].each do |reader|
      listed = scoped(reader)

      [@open, @closed, @managed].each do |inventory|
        shown = policy_for(reader, inventory).apply(:show?)

        assert_equal shown, listed.include?(inventory),
          "the scope and show? disagreed about #{inventory.visibility} " \
          "inventory #{inventory.name} for #{reader.username}"
      end
    end
  end

  test "an officers-only inventory is kept from a member who only reads" do
    assert_equal [@open], scoped(@member)
    refute policy_for(@member, @closed).apply(:show?)
  end

  test "an officer sees every inventory in the fleet" do
    assert_equal [@open, @closed, @managed].sort_by(&:id), scoped(@officer).sort_by(&:id)
  end

  test "a manager reaches the officers-only store they are answerable for, and no other" do
    listed = scoped(@manager)

    assert_includes listed, @managed
    assert_includes listed, @open
    refute_includes listed, @closed
  end

  test "someone outside the fleet is shown nothing" do
    assert_empty scoped(@stranger)
  end

  # Privileges and visibility are separate gates: holding the write privilege
  # for the fleet says nothing about whether this is a store you may see.
  test "write privileges do not reach an inventory the reader cannot see" do
    writer = member_with(["fleet:inventories:read", "fleet:inventories:update", "fleet:inventories:delete"])

    assert policy_for(writer, @open).apply(:update?)
    refute policy_for(writer, @closed).apply(:update?)
    refute policy_for(writer, @closed).apply(:destroy?)
  end

  test "neither relation scope answers without a fleet" do
    [:default, :visible].each do |name|
      assert_raises(ArgumentError, "the #{name} scope answered without a fleet") do
        FleetInventoryPolicy.new(nil, user: @member)
          .apply_scope(FleetInventory.all, type: :active_record_relation, name: name)
      end
    end
  end

  # The manager exception lifts the officers-only bar, not the baseline read
  # privilege -- and the scope has to agree with `show?` about that, or a
  # reader with no inventory access at all is listed one thing and refused it.
  test "a manager whose role carries no inventory access still sees nothing" do
    manager = member_with([])
    create(:fleet_inventory, :officers_only, fleet: @fleet, manager: manager)

    assert_empty scoped(manager)
    refute policy_for(manager, @open).apply(:show?)
  end

  # The privilege lists are independent of each other: a role may carry
  # `fleet:inventories:update` without `:read`. The lookup a write goes through
  # must not decide that write by failing to find the record, so the `visible`
  # scope answers on visibility alone and leaves the privilege to `update?`.
  test "the visible scope finds a record for a writer who cannot read" do
    writer = member_with(["fleet:inventories:update"])

    assert_includes scoped(writer, :visible), @open
    assert policy_for(writer, @open).apply(:update?)

    assert_empty scoped(writer), "the default scope is a read, and this role cannot read"
  end

  test "the visible scope still hides an officers-only inventory" do
    writer = member_with(["fleet:inventories:update"])

    refute_includes scoped(writer, :visible), @closed
    refute policy_for(writer, @closed).apply(:update?)
  end
end
