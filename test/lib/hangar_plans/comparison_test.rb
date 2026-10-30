# frozen_string_literal: true

require "test_helper"

class HangarPlans::ComparisonTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @cutlass = create(:model, name: "Cutlass Black", pledge_price: 100)
    @constellation = create(:model, name: "Constellation Andromeda", pledge_price: 250)
    @carrack = create(:model, name: "Carrack", pledge_price: 600)
    @plan = create(:hangar_plan, user: @user)
  end

  test "each ship of the hangar is kept, upgraded, melted or left out" do
    kept = create(:vehicle, user: @user, model: @cutlass)
    upgraded = create(:vehicle, user: @user, model: @cutlass)
    melted = create(:vehicle, user: @user, model: @constellation)
    unassigned = create(:vehicle, user: @user, model: @constellation)

    keep = slot_for(@cutlass)
    @plan.acquisitions.create!(candidate: keep, start_kind: "owned", source_vehicle: kept)
    upgrade = slot_for(@carrack)
    route = @plan.acquisitions.new(candidate: upgrade, start_kind: "owned", source_vehicle: upgraded)
    route.upgrade_steps.build(source_kind: "store", origin_model: @cutlass, target_model: @carrack, position: 0)
    route.save!
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle: melted)

    statuses = HangarPlans::Comparison.new(@plan).vehicles.to_h { |entry| [entry.vehicle.id, entry.status] }

    assert_equal({kept.id => "kept", upgraded.id => "upgraded", melted.id => "melted", unassigned.id => "unassigned"}, statuses)
  end

  test "a route on a slot that has not picked its ship leaves the ship unassigned" do
    vehicle = create(:vehicle, user: @user, model: @cutlass)
    candidate = slot_for(@cutlass)
    create(:hangar_plan_candidate, slot: candidate.slot, model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "owned", source_vehicle: vehicle)

    assert_equal ["unassigned"], HangarPlans::Comparison.new(@plan).vehicles.map(&:status)
  end

  test "a hangar ship paired with another ship but no route yet is unrouted" do
    vehicle = create(:vehicle, user: @user, model: @cutlass)
    candidate = slot_for(@carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "owned", source_vehicle: vehicle)

    entry = HangarPlans::Comparison.new(@plan).vehicles.sole

    assert_equal "unrouted", entry.status
    assert_equal @carrack, entry.target_model
    assert_empty HangarPlans::Comparison.new(@plan).gaps
  end

  test "model counts change between the hangar and the hangar after the plan" do
    create(:vehicle, user: @user, model: @cutlass)
    create(:vehicle, user: @user, model: @constellation)
    slot_for(@carrack)
    slot_for(@cutlass, quantity: 2)
    undecided = create(:hangar_plan_slot, hangar_plan: @plan)
    create(:hangar_plan_candidate, slot: undecided, model: @constellation)
    create(:hangar_plan_candidate, slot: undecided, model: @carrack)

    changes = HangarPlans::Comparison.new(@plan).models.to_h { |diff| [diff.model.name, diff.change] }

    # The Constellation is in no slot and not melted, so it stays; the Cutlass
    # left out fills one of the two Cutlass units, which still have no route.
    assert_equal({"Carrack" => "added", "Constellation Andromeda" => "unchanged", "Cutlass Black" => "more"}, changes)
  end

  test "a melted ship goes, and one the plan leaves alone stays" do
    melted = create(:vehicle, user: @user, model: @constellation)
    create(:vehicle, user: @user, model: @cutlass)
    @plan.melts.create!(vehicle: melted)

    diffs = HangarPlans::Comparison.new(@plan).models.to_h { |diff| [diff.model.name, [diff.left_count, diff.right_count]] }

    assert_equal({"Constellation Andromeda" => [1, 0], "Cutlass Black" => [1, 1]}, diffs)
  end

  test "a ship the plan has not settled yet stays, marked as it is" do
    pending = create(:vehicle, user: @user, model: @constellation)
    change = create(:vehicle, user: @user, model: @cutlass)
    @plan.vehicle_marks.create!(vehicle: pending)
    @plan.vehicle_marks.create!(vehicle: change, mark: "change")

    comparison = HangarPlans::Comparison.new(@plan)

    assert_equal({pending.id => "pending", change.id => "change"}, comparison.vehicles.to_h { |entry| [entry.vehicle.id, entry.status] })
    assert_equal({"Constellation Andromeda" => [1, 1], "Cutlass Black" => [1, 1]},
      comparison.models.to_h { |diff| [diff.model.name, [diff.left_count, diff.right_count]] })
  end

  test "a route settles a marked ship, and removing it brings the mark back" do
    vehicle = create(:vehicle, user: @user, model: @cutlass)
    @plan.vehicle_marks.create!(vehicle:, mark: "change")
    candidate = @plan.slots.create!(label: "Fighter").candidates.create!(model: @cutlass)
    @plan.acquisitions.create!(candidate:, start_kind: "owned", source_vehicle: vehicle)

    assert_equal ["kept"], HangarPlans::Comparison.new(@plan).vehicles.map(&:status)

    @plan.acquisitions.destroy_all
    assert_equal ["change"], HangarPlans::Comparison.new(@plan.reload).vehicles.map(&:status)
  end

  test "the other ships of a melted pledge go with it" do
    melted = create(:vehicle, user: @user, model: @constellation, rsi_pledge_id: "pack")
    sibling = create(:vehicle, user: @user, model: @cutlass, rsi_pledge_id: "pack")
    @plan.melts.create!(vehicle: melted)

    statuses = HangarPlans::Comparison.new(@plan).vehicles.to_h { |entry| [entry.vehicle.id, entry.status] }

    assert_equal({melted.id => "melted", sibling.id => "melted"}, statuses)
  end

  test "units of a decided slot without a route are gaps" do
    slot_for(@carrack, quantity: 2)

    gap = HangarPlans::Comparison.new(@plan).gaps.first

    assert_equal [@carrack, 2], [gap.model, gap.count]
  end

  test "upgrade names from the RSI hangar resolve to ships" do
    create(:hangar_plan_slot, hangar_plan: @plan)
    create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Cutlass Black To Carrack Warbond Edition")

    upgrade = HangarPlans::Resources.new(@plan).upgrades.first

    assert_equal [@cutlass, @carrack], [upgrade.from_model, upgrade.to_model]
  end

  private def slot_for(model, quantity: 1)
    slot = create(:hangar_plan_slot, hangar_plan: @plan, quantity:)
    create(:hangar_plan_candidate, slot:, model:)
  end
end
