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

  test "model counts change between the hangar and the plan's decided slots" do
    create(:vehicle, user: @user, model: @cutlass)
    create(:vehicle, user: @user, model: @constellation)
    slot_for(@carrack)
    slot_for(@cutlass, quantity: 2)
    undecided = create(:hangar_plan_slot, hangar_plan: @plan)
    create(:hangar_plan_candidate, slot: undecided, model: @constellation)
    create(:hangar_plan_candidate, slot: undecided, model: @carrack)

    changes = HangarPlans::Comparison.new(@plan).models.to_h { |diff| [diff.model.name, diff.change] }

    assert_equal({"Carrack" => "added", "Constellation Andromeda" => "removed", "Cutlass Black" => "more"}, changes)
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
