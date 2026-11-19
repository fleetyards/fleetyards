# frozen_string_literal: true

require "test_helper"

class HangarPlans::DriftTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @gladius = create(:model, name: "Gladius", pledge_price: 90)
    @carrack = create(:model, name: "Carrack", pledge_price: 600)
    @kept = create(:vehicle, user: @user, model: @gladius)
    @plan = @user.hangar_plans.new(name: "Plan")
    HangarPlans::Builder.new(@plan, source: "hangar").run
    candidate = @plan.slots.create!(label: "Gladius").candidates.create!(model: @gladius)
    @plan.acquisitions.create!(candidate:, start_kind: "owned", source_vehicle: @kept)
  end

  test "a fresh plan has not drifted" do
    assert_not HangarPlans::Drift.new(@plan).drifted?
  end

  test "a ship the plan relies on that left the hangar is flagged, never removed" do
    @kept.destroy!

    drift = HangarPlans::Drift.new(@plan.reload)

    assert_equal ["acquisition"], drift.missing_sources.map(&:kind)
    assert_equal 1, @plan.acquisitions.count
  end

  test "a kept ship that left the hangar is flagged" do
    gone = create(:vehicle, user: @user, model: @carrack)
    @plan.vehicle_marks.create!(vehicle: gone, mark: "keep")
    gone.destroy!

    missing = HangarPlans::Drift.new(@plan.reload).missing_sources

    assert_equal [["mark", @carrack]], missing.map { |issue| [issue.kind, issue.planned_model] }
  end

  test "a ship changed into another model is flagged" do
    @kept.update_columns(model_id: @carrack.id)

    changed = HangarPlans::Drift.new(@plan.reload).changed_sources

    assert_equal [@gladius, @carrack], [changed.first.planned_model, changed.first.current_model]
  end

  test "ships bought since the plan was based are listed" do
    travel 1.minute do
      added = create(:vehicle, user: @user, model: @carrack)

      assert_equal [added], HangarPlans::Drift.new(@plan).new_vehicles.to_a
    end
  end

  test "a wishlist ship bought since the plan was based is listed" do
    wanted = travel(-1.day) { create(:vehicle, user: @user, model: @carrack, wanted: true) }
    plan = @user.hangar_plans.new(name: "Later")
    HangarPlans::Builder.new(plan, source: "hangar").run

    wanted.update!(wanted: false)

    assert_equal [wanted], HangarPlans::Drift.new(plan.reload).new_vehicles
  end

  test "a price change shows the old and the new total" do
    slot = @plan.slots.create!(label: "Carrack")
    candidate = slot.candidates.create!(model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: @carrack)
    @carrack.update_columns(pledge_price: 650)

    drift = HangarPlans::Drift.new(@plan.reload)

    assert_equal [600, 650], [drift.previous_total, drift.current_total]
    assert_predicate drift, :drifted?
  end

  test "a rebase marks new ships to decide, keeps edits and takes prices again" do
    slot = @plan.slots.create!(label: "Carrack")
    candidate = slot.candidates.create!(model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: @carrack, price_override: 500)
    @carrack.update_columns(pledge_price: 650)

    bought = travel 1.minute do
      create(:vehicle, user: @user, model: @gladius).tap { HangarPlans::Drift.new(@plan).rebase! }
    end

    @plan.reload
    assert_includes @plan.vehicle_marks.pluck(:vehicle_id, :mark), [bought.id, "pending"]
    assert_equal 500, @plan.acquisitions.find_by(start_kind: "store").price_override
    assert_not HangarPlans::Drift.new(@plan).drifted?
  end

  test "a rebase drops the marks of ships deleted from the hangar" do
    gone = create(:vehicle, user: @user, model: @carrack)
    @plan.vehicle_marks.create!(vehicle: gone, mark: "keep")
    gone.destroy!

    HangarPlans::Drift.new(@plan.reload).rebase!

    @plan.reload
    assert_not @plan.vehicle_marks.exists?(vehicle_id: gone.id)
    assert @plan.vehicle_marks.exists?(vehicle_id: @kept.id)
    assert_not HangarPlans::Drift.new(@plan).drifted?
  end

  test "a rebase moves a route on to the upgraded ship that replaced its start" do
    cutlass = create(:model, name: "Cutlass", pledge_price: 100)
    start = create(:vehicle, user: @user, model: @gladius)
    candidate = @plan.slots.create!(label: "Hauler").candidates.create!(model: cutlass)
    route = @plan.acquisitions.build(candidate:, start_kind: "owned", source_vehicle: start)
    route.upgrade_steps.build(source_kind: "store", origin_model: @gladius, target_model: cutlass, position: 0)
    route.save!

    upgraded = travel 1.minute do
      start.update!(wanted: true)
      create(:vehicle, user: @user, model: cutlass).tap { HangarPlans::Drift.new(@plan.reload).rebase! }
    end

    route.reload
    assert_equal [upgraded, cutlass], [route.source_vehicle, route.start_model]
    assert_empty route.upgrade_steps
    assert_not @plan.reload.vehicle_marks.exists?(vehicle_id: upgraded.id)
    assert_empty HangarPlans::Drift.new(@plan).missing_sources
  end

  test "a rebase moves a route on to the step its ship reached" do
    cutlass = create(:model, name: "Cutlass", pledge_price: 100)
    start = create(:vehicle, user: @user, model: @gladius)
    candidate = @plan.slots.create!(label: "Hauler").candidates.create!(model: @carrack)
    route = @plan.acquisitions.build(candidate:, start_kind: "owned", source_vehicle: start)
    route.upgrade_steps.build(source_kind: "store", origin_model: @gladius, target_model: cutlass, position: 0)
    route.upgrade_steps.build(source_kind: "store", origin_model: cutlass, target_model: @carrack, position: 1)
    route.save!

    upgraded = travel 1.minute do
      start.destroy!
      create(:vehicle, user: @user, model: cutlass).tap { HangarPlans::Drift.new(@plan.reload).rebase! }
    end

    route.reload
    assert_equal [upgraded, cutlass], [route.source_vehicle, route.start_model]
    assert_equal [[cutlass.id, @carrack.id]], route.upgrade_steps.pluck(:from_model_id, :to_model_id)
  end

  test "a rebase leaves a route flagged when nothing along it arrived" do
    @kept.destroy!

    HangarPlans::Drift.new(@plan.reload).rebase!

    assert_equal ["acquisition"], HangarPlans::Drift.new(@plan.reload).missing_sources.map(&:kind)
  end

  test "a rebase ends a melt whose ship is gone and counts its credit as held" do
    melted = create(:vehicle, user: @user, model: @carrack)
    @plan.update!(starting_credit: 50)
    @plan.melts.create!(vehicle: melted, value_override: 550)
    melted.update!(wanted: true)

    HangarPlans::Drift.new(@plan.reload).rebase!

    @plan.reload
    assert_empty @plan.melts
    assert_equal 600, @plan.starting_credit
    assert_empty HangarPlans::Drift.new(@plan).missing_sources
  end

  test "a rebase takes the ship bought back from a melt as the route's start" do
    melted = create(:vehicle, user: @user, model: @carrack)
    @plan.melts.create!(vehicle: melted)
    candidate = @plan.slots.create!(label: "Explorer").candidates.create!(model: @carrack)
    route = @plan.acquisitions.create!(candidate:, start_kind: "melted", source_vehicle: melted)

    returned = travel 1.minute do
      melted.update!(wanted: true)
      create(:vehicle, user: @user, model: @carrack).tap { HangarPlans::Drift.new(@plan.reload).rebase! }
    end

    assert_equal ["owned", returned], [route.reload.start_kind, route.source_vehicle]
    assert_empty @plan.reload.melts
    assert_not HangarPlans::Drift.new(@plan).drifted?
  end

  test "a rebase counts no credit for a melt whose pledge a route bought back" do
    melted = create(:vehicle, user: @user, model: @carrack)
    @plan.update!(starting_credit: 50)
    @plan.melts.create!(vehicle: melted, value_override: 550)
    candidate = @plan.slots.create!(label: "Explorer").candidates.create!(model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "melted", source_vehicle: melted)

    travel 1.minute do
      melted.update!(wanted: true)
      create(:vehicle, user: @user, model: @carrack).tap { HangarPlans::Drift.new(@plan.reload).rebase! }
    end

    @plan.reload
    assert_empty @plan.melts
    assert_equal 50, @plan.starting_credit
  end

  test "a rebase keeps a melt whose ship is hidden for now" do
    melted = create(:vehicle, user: @user, model: @carrack)
    @plan.update!(starting_credit: 50)
    @plan.melts.create!(vehicle: melted, value_override: 550)
    melted.update!(hidden: true)

    HangarPlans::Drift.new(@plan.reload).rebase!

    @plan.reload
    assert_equal 1, @plan.melts.count
    assert_equal 50, @plan.starting_credit
  end

  test "a rebase keeps a melt whose ship is still to be bought back" do
    melted = create(:vehicle, user: @user, model: @carrack)
    @plan.melts.create!(vehicle: melted)
    candidate = @plan.slots.create!(label: "Explorer").candidates.create!(model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "melted", source_vehicle: melted)
    melted.update!(wanted: true)

    HangarPlans::Drift.new(@plan.reload).rebase!

    assert_equal 1, @plan.reload.melts.count
  end

  test "a rebase drops the mark of a kept ship moved to the wishlist" do
    gone = create(:vehicle, user: @user, model: @carrack)
    @plan.vehicle_marks.create!(vehicle: gone, mark: "keep")
    gone.update!(wanted: true)

    HangarPlans::Drift.new(@plan.reload).rebase!

    assert_not @plan.reload.vehicle_marks.exists?(vehicle_id: gone.id)
  end

  test "a rebase keeps the mark of a ship hidden for now" do
    hidden = create(:vehicle, user: @user, model: @carrack)
    @plan.vehicle_marks.create!(vehicle: hidden, mark: "keep")
    hidden.update!(hidden: true)

    HangarPlans::Drift.new(@plan.reload).rebase!

    assert_equal "keep", @plan.vehicle_marks.find_by(vehicle_id: hidden.id).mark
  end

  test "a rebase takes a ship bought back as the route's start while the buy-back list still names it" do
    pledge = create(:buyback_pledge, user: @user, name: "Standalone Ship - Carrack")
    candidate = @plan.slots.create!(label: "Explorer").candidates.create!(model: @carrack)
    route = @plan.acquisitions.create!(candidate:, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)

    bought = travel 1.minute do
      create(:vehicle, user: @user, model: @carrack).tap { HangarPlans::Drift.new(@plan.reload).rebase! }
    end

    route.reload
    assert_equal ["owned", bought, nil], [route.start_kind, route.source_vehicle, route.buyback_pledge]
    assert_not @plan.reload.vehicle_marks.exists?(vehicle_id: bought.id)
    assert_not HangarPlans::Drift.new(@plan).drifted?
  end

  test "a ship bought for a route is listed as carried out rather than as new" do
    candidate = @plan.slots.create!(label: "Explorer").candidates.create!(model: @carrack)
    route = @plan.acquisitions.create!(candidate:, start_kind: "store")

    travel 1.minute do
      bought = create(:vehicle, user: @user, model: @carrack)
      drift = HangarPlans::Drift.new(@plan.reload)

      assert_equal [[route.id, bought.id]], drift.progress.arrivals.map { |arrival| [arrival.acquisition.id, arrival.vehicle.id] }
      assert_empty drift.new_vehicles
      assert_predicate drift, :drifted?
    end
  end

  test "a rebase takes a ship waiting for a decision that arrived after the route was planned" do
    candidate = @plan.slots.create!(label: "Explorer").candidates.create!(model: @carrack)
    route = @plan.acquisitions.create!(candidate:, start_kind: "store")
    bought = travel(1.minute) { create(:vehicle, user: @user, model: @carrack) }
    travel(2.minutes) { HangarPlanVehicleMark.write(@plan, [bought], "pending") }
    @plan.update!(based_on_vehicle_ids: @plan.live_vehicles.pluck(:id))

    HangarPlans::Drift.new(@plan.reload).rebase!

    assert_equal ["owned", bought], [route.reload.start_kind, route.source_vehicle]
  end

  test "a rebase leaves a route to buy alone for a ship that was there before it" do
    waiting = create(:vehicle, user: @user, model: @carrack)
    HangarPlanVehicleMark.write(@plan, [waiting], "pending")
    @plan.update!(based_on_vehicle_ids: @plan.live_vehicles.pluck(:id))
    candidate = travel(1.minute) { @plan.slots.create!(label: "Explorer").candidates.create!(model: @carrack) }
    route = travel(1.minute) { @plan.acquisitions.create!(candidate:, start_kind: "store") }

    travel(2.minutes) { HangarPlans::Drift.new(@plan.reload).rebase! }

    assert_equal "store", route.reload.start_kind
  end

  test "a rebase takes an upgrade to buy from the hangar once the user holds it" do
    cutlass = create(:model, name: "Cutlass", pledge_price: 100)
    candidate = @plan.slots.create!(label: "Hauler").candidates.create!(model: @carrack)
    route = @plan.acquisitions.build(candidate:, start_kind: "store", start_model: @gladius)
    first = route.upgrade_steps.build(source_kind: "store", origin_model: @gladius, target_model: cutlass, position: 0)
    second = route.upgrade_steps.build(source_kind: "store", origin_model: cutlass, target_model: @carrack, position: 1)
    route.save!
    held = create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Cutlass to Carrack")

    drift = HangarPlans::Drift.new(@plan.reload)

    assert_equal [[second.id, held.id]], drift.progress.held_upgrades.map { |upgrade| [upgrade.step.id, upgrade.item.id] }
    assert_predicate drift, :drifted?

    drift.rebase!

    assert_equal ["store", nil], first.reload.slice(:source_kind, :hangar_pledge_item_id).values
    assert_equal ["owned_ccu", held.id, 0], second.reload.slice(:source_kind, :hangar_pledge_item_id, :price_snapshot).values
    assert_not HangarPlans::Drift.new(@plan.reload).drifted?
  end

  test "a held upgrade pays for as many steps as the user holds of it" do
    held = create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Gladius to Carrack", quantity: 1)
    steps = 2.times.map do |index|
      candidate = @plan.slots.create!(label: "Explorer #{index}").candidates.create!(model: @carrack)
      route = @plan.acquisitions.build(candidate:, start_kind: "store", start_model: @gladius)
      route.upgrade_steps.build(source_kind: "store", origin_model: @gladius, target_model: @carrack, position: 0)
      route.save!
      route.upgrade_steps.first
    end

    HangarPlans::Drift.new(@plan.reload).rebase!

    assert_equal [["owned_ccu", held.id], ["store", nil]], steps.map { |step| step.reload.slice(:source_kind, :hangar_pledge_item_id).values }
  end

  test "an upgrade bought back is taken from the hangar rather than flagged as gone" do
    pledge = create(:buyback_pledge, user: @user, kind: "upgrade", name: "Upgrade - Gladius to Carrack")
    candidate = @plan.slots.create!(label: "Explorer").candidates.create!(model: @carrack)
    route = @plan.acquisitions.build(candidate:, start_kind: "owned", source_vehicle: @kept)
    step = route.upgrade_steps.build(source_kind: "buyback", buyback_pledge: pledge, origin_model: @gladius, target_model: @carrack, position: 0)
    @plan.acquisitions.where(source_vehicle: @kept).where.not(id: route.id).destroy_all
    route.save!
    pledge.destroy!
    create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Gladius to Carrack")

    drift = HangarPlans::Drift.new(@plan.reload)

    assert_empty drift.missing_sources
    drift.rebase!
    assert_equal "owned_ccu", step.reload.source_kind
  end
end
