# frozen_string_literal: true

require "test_helper"

class FleetInventoryItemHolderTest < ActiveSupport::TestCase
  setup do
    @alice = create(:user)
    @bob = create(:user)
    @fleet = create(:fleet, members: [@alice, @bob])
    @inventory = create(:fleet_inventory, fleet: @fleet)
  end

  def deposit(holder, quantity, **attributes)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "aUEC", category: :other, unit: :units,
      quantity:, holder:, **attributes)
  end

  def withdrawal(holder, quantity, **attributes)
    build(:fleet_inventory_item, :withdrawal, fleet_inventory: @inventory, name: "aUEC", category: :other,
      unit: :units, quantity:, holder:, **attributes)
  end

  test "a withdrawal comes out of its holder's share" do
    deposit(@alice, 100)
    deposit(@bob, 50)

    assert_predicate withdrawal(@alice, 100), :valid?

    overdrawn = withdrawal(@bob, 60)

    assert_not overdrawn.valid?
    assert_includes overdrawn.errors[:quantity].join, "exceeds what #{@bob.username} holds (50.0)"
  end

  test "the unassigned share is a share of its own" do
    deposit(nil, 10)
    deposit(@alice, 100)

    assert_predicate withdrawal(nil, 10), :valid?
    assert_not withdrawal(nil, 11).valid?
  end

  test "a crafted lot is checked against its holder's share of that lot" do
    component = create(:component)
    blueprint = create(:blueprint, craftable: component)
    slot = create(:blueprint_cost_slot, build: blueprint.build, position: 1)
    create(:blueprint_cost_modifier, slot:)
    blueprint.reload
    lot = {name: component.name, category: :component, unit: :units, item: component,
           crafted_blueprint: blueprint, crafted_qualities: {1 => 500}}

    create(:fleet_inventory_item, fleet_inventory: @inventory, quantity: 2, holder: @alice, **lot)
    create(:fleet_inventory_item, fleet_inventory: @inventory, quantity: 5, holder: @bob, **lot)

    entry = build(:fleet_inventory_item, :withdrawal, fleet_inventory: @inventory, quantity: 3, holder: @alice, **lot)

    assert_not entry.valid?
  end

  test "a deposit's holder must be an accepted member" do
    outsider = create(:user)

    entry = build(:fleet_inventory_item, fleet_inventory: @inventory, holder: outsider)

    assert_not entry.valid?
    assert_includes entry.errors.details[:holder_id].pluck(:error), :not_a_member
  end

  test "a former member can still hand back what they carry" do
    deposit(@alice, 100)
    @fleet.fleet_memberships.find_by(user: @alice).destroy

    assert_predicate withdrawal(@alice, 100), :valid?
  end
end
