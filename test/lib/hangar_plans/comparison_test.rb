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

  test "a start for a slot that has not picked its ship waits without an end" do
    vehicle = create(:vehicle, user: @user, model: @cutlass)
    candidate = slot_for(@cutlass)
    create(:hangar_plan_candidate, slot: candidate.slot, model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "owned", source_vehicle: vehicle)

    comparison = HangarPlans::Comparison.new(@plan)
    entry = comparison.vehicles.sole

    assert_equal "unrouted", entry.status
    assert_nil entry.target_model
    # Until the slot picks its ship, the hangar after the plan still holds it.
    assert_equal({"Cutlass Black" => "unchanged"}, comparison.models.to_h { |diff| [diff.model.name, diff.change] })
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
    2.times { slot_for(@cutlass) }
    undecided = create(:hangar_plan_slot, hangar_plan: @plan)
    create(:hangar_plan_candidate, slot: undecided, model: @constellation)
    create(:hangar_plan_candidate, slot: undecided, model: @carrack)

    changes = HangarPlans::Comparison.new(@plan).models.to_h { |diff| [diff.model.name, diff.change] }

    # The Constellation is in no slot and not melted, so it stays; the Cutlass
    # left out fills one of the two Cutlass slots, which still have no route.
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

  test "decided slots without a route are gaps" do
    2.times { slot_for(@carrack) }

    gaps = HangarPlans::Comparison.new(@plan).gaps

    assert_equal [[@carrack, 1], [@carrack, 1]], gaps.map { |gap| [gap.model, gap.count] }
  end

  test "upgrade names from the RSI hangar resolve to ships" do
    create(:hangar_plan_slot, hangar_plan: @plan)
    create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Cutlass Black To Carrack Warbond Edition")

    upgrade = HangarPlans::Resources.new(@plan).upgrades.first

    assert_equal [@cutlass, @carrack], [upgrade.from_model, upgrade.to_model]
  end

  test "a planned ship whose model goes inactive is not lost" do
    model = create(:model, on_sale: true)
    melted = create(:vehicle, user: @user, model:)
    melt = create(:hangar_plan_melt, hangar_plan: @plan, vehicle: melted)

    model.update!(active: false)

    assert_not HangarPlan.find(@plan.id).melts.find(melt.id).vehicle_missing?
  end

  test "a keep mark on an inactive model does not block melting its pledge" do
    beacon = create(:model)
    ship = create(:vehicle, user: @user, model: create(:model), rsi_pledge_id: "pledge")
    kept = create(:vehicle, user: @user, model: beacon, rsi_pledge_id: "pledge")
    @plan.vehicle_marks.create!(vehicle: kept, mark: "keep")

    assert_not build(:hangar_plan_melt, hangar_plan: @plan, vehicle: ship).valid?

    beacon.update!(active: false)

    assert build(:hangar_plan_melt, hangar_plan: @plan, vehicle: ship).valid?
  end

  test "an inactive model is no ship to plan with" do
    beacon = create(:model, name: "Geotack-X Planetary Beacon", active: false)
    create(:vehicle, user: @user, model: beacon)

    assert_not_includes @plan.live_vehicles.map(&:model), beacon
    assert_includes @plan.pledged_vehicles.map(&:model), beacon
    assert_not_includes HangarPlans::Comparison.new(@plan).vehicles.map { |entry| entry.vehicle.model }, beacon
  end

  test "a pledge says whether it holds a ship alone" do
    plan = create(:hangar_plan, user: (user = create(:user)))
    model = create(:model)
    alone = create(:vehicle, user:, model:, rsi_pledge_id: "alone", rsi_pledge_name: "Standalone Ship - Pulse plus Dominion Paint", rsi_pledge_item_count: 2)
    bare = create(:vehicle, user:, model:, rsi_pledge_id: "bare", rsi_pledge_item_count: 1)
    packed = create(:vehicle, user:, model:, rsi_pledge_id: "pack", rsi_pledge_name: "Package - Praetorian Pack")
    create(:vehicle, user:, model:, rsi_pledge_id: "pack", rsi_pledge_name: "Package - Praetorian Pack")
    single = create(:vehicle, user:, model:, rsi_pledge_id: "single", rsi_pledge_name: "VIP Wing Commander", rsi_pledge_item_count: 3)
    unsynced = create(:vehicle, user:, model:)
    uncounted = create(:vehicle, user:, model:, rsi_pledge_id: "uncounted", rsi_pledge_name: "Aurora Starter Pack")
    named_package = create(:vehicle, user:, model:, rsi_pledge_id: "named", rsi_pledge_name: "Package - Dominus Pack")

    contents = HangarPlans::PledgeContents.new(plan, [alone, bare, packed, single, unsynced, uncounted, named_package])

    assert_equal true, contents.for(alone).standalone
    assert_equal true, contents.for(bare).standalone
    assert_equal false, contents.for(packed).standalone
    assert_equal false, contents.for(single).standalone
    assert_nil contents.for(unsynced).standalone
    assert_nil contents.for(uncounted).standalone
    assert_equal false, contents.for(named_package).standalone
  end

  test "a start a slot with no ship holds leaves the hangar ship as it is" do
    plan = create(:hangar_plan, user: (user = create(:user)))
    vehicle = create(:vehicle, user:, model: create(:model))
    plan.acquisitions.create!(slot: create(:hangar_plan_slot, hangar_plan: plan), start_kind: "owned", source_vehicle: vehicle)

    comparison = HangarPlans::Comparison.new(plan)

    assert_equal ["unrouted"], comparison.vehicles.map(&:status)
    assert_equal [vehicle], comparison.fleet.map(&:vehicle)
    assert_empty comparison.gaps
  end

  test "a pledge bought back brings its other ships into the hangar after the plan" do
    pledge = create(:buyback_pledge, user: @user, kind: "package", name: "Package - Trio",
      ship_names: ["Carrack", "Cutlass Black", "Constellation Andromeda"])
    pledge_start = @plan.acquisitions.create!(candidate: slot_for(@carrack), start_kind: "buyback", buyback_pledge: pledge,
      start_model: @carrack)
    @plan.acquisitions.create!(candidate: slot_for(@cutlass), start_kind: "bundled", bundled_with: pledge_start,
      start_model: @cutlass)

    # The Cutlass fills its slot; the Constellation no slot takes comes along.
    assert_equal({"Carrack" => 1, "Constellation Andromeda" => 1, "Cutlass Black" => 1},
      HangarPlans::Comparison.new(@plan).models.to_h { |diff| [diff.model.name, diff.right_count] })
  end

  test "a pledge a slot still choosing its ship buys back brings nothing along yet" do
    pledge = create(:buyback_pledge, user: @user, kind: "package", name: "Package - Duo", ship_names: ["Carrack", "Cutlass Black"])
    slot = create(:hangar_plan_slot, hangar_plan: @plan)
    @plan.acquisitions.create!(slot:, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)

    assert_empty HangarPlans::Comparison.new(@plan).fleet
  end

  test "a bundled ship a slot still choosing its ship starts from stays in the hangar after the plan" do
    pledge = create(:buyback_pledge, user: @user, kind: "package", name: "Package - Duo", ship_names: ["Carrack", "Cutlass Black"])
    pledge_start = @plan.acquisitions.create!(candidate: slot_for(@carrack), start_kind: "buyback", buyback_pledge: pledge,
      start_model: @carrack)
    choosing = slot_for(@cutlass)
    create(:hangar_plan_candidate, slot: choosing.slot, model: @constellation)
    @plan.acquisitions.create!(candidate: choosing, start_kind: "bundled", bundled_with: pledge_start, start_model: @cutlass)

    assert_equal({"Carrack" => 1, "Cutlass Black" => 1},
      HangarPlans::Comparison.new(@plan).models.to_h { |diff| [diff.model.name, diff.right_count] })
  end

  test "a bundled ship no slot starts from fills a slot of its model that has no route yet" do
    pledge = create(:buyback_pledge, user: @user, kind: "package", name: "Package - Duo", ship_names: ["Carrack", "Cutlass Black"])
    @plan.acquisitions.create!(candidate: slot_for(@carrack), start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)
    slot_for(@cutlass)

    assert_equal({"Carrack" => 1, "Cutlass Black" => 1},
      HangarPlans::Comparison.new(@plan).models.to_h { |diff| [diff.model.name, diff.right_count] })
  end

  private def slot_for(model)
    slot = create(:hangar_plan_slot, hangar_plan: @plan)
    create(:hangar_plan_candidate, slot:, model:)
  end
end
