# frozen_string_literal: true

require "test_helper"

class HangarPlanTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @plan = create(:hangar_plan, user: @user)
    @cutlass = create(:model, pledge_price: 100, on_sale: true)
    @constellation = create(:model, pledge_price: 250, on_sale: true)
    @carrack = create(:model, pledge_price: 600, on_sale: true)
    @slot = create(:hangar_plan_slot, hangar_plan: @plan)
    @candidate = create(:hangar_plan_candidate, slot: @slot, model: @carrack)
  end

  test "a user holds at most twenty plans" do
    (HangarPlan::MAX_PER_USER - 1).times { create(:hangar_plan, user: @user) }

    plan = build(:hangar_plan, user: @user)

    assert_not plan.valid?
    assert plan.errors.of_kind?(:base, :plan_limit_reached)
  end

  test "a plan holds at most two hundred slots" do
    HangarPlanSlot.insert_all!(Array.new(HangarPlanSlot::MAX_PER_PLAN - 1) { |index|
      {hangar_plan_id: @plan.id, label: "Slot #{index}", position: index + 1, created_at: Time.current, updated_at: Time.current}
    })

    slot = build(:hangar_plan_slot, hangar_plan: @plan)

    assert_not slot.valid?
    assert slot.errors.of_kind?(:base, :slot_limit_reached)
  end

  test "a slot is open, decided or undecided by how many candidates it has" do
    open_slot = create(:hangar_plan_slot, hangar_plan: @plan)
    undecided = create(:hangar_plan_slot, hangar_plan: @plan)
    create(:hangar_plan_candidate, slot: undecided, model: @cutlass)
    create(:hangar_plan_candidate, slot: undecided, model: @constellation)

    assert_equal "open", open_slot.reload.state
    assert_equal "decided", @slot.reload.state
    assert_equal "undecided", undecided.reload.state
  end

  test "a slot's filters say which ships fit it" do
    @carrack.update!(classification: "exploration", size: "large", cargo: 456)
    slot = create(:hangar_plan_slot, hangar_plan: @plan,
      filters: {classification_in: ["exploration"], pledge_price_lteq: "700", cargo_gteq: 400, on_sale_eq: "true"})

    assert_equal({"classification_in" => ["exploration"], "pledge_price_lteq" => 700.0, "cargo_gteq" => 400, "on_sale_eq" => true},
      slot.filters)
    assert slot.matches?(@carrack)
    assert_not slot.matches?(@cutlass)
  end

  test "a slot drops empty filters and rejects unknown ones" do
    slot = build(:hangar_plan_slot, hangar_plan: @plan, filters: {size_in: [], pledge_price_gteq: ""})

    assert_predicate slot, :valid?
    assert_empty slot.filters

    slot.filters = {crew_gteq: 2}
    assert_not slot.valid?

    slot.filters = {pledge_price_lteq: "cheap"}
    assert_not slot.valid?
  end

  test "a candidate's paint has to belong to its ship" do
    candidate = build(:hangar_plan_candidate, slot: create(:hangar_plan_slot, hangar_plan: @plan),
      model: @cutlass, model_paint: create(:model_paint, model: @carrack))

    assert_not candidate.valid?
    assert candidate.errors.of_kind?(:model_paint_id, :invalid)
  end

  test "an owned ship starts a route once" do
    vehicle = create(:vehicle, user: @user, model: @carrack)
    @slot.update!(quantity: 2)

    create_acquisition(start_kind: "owned", source_vehicle: vehicle)
    second = build_acquisition(start_kind: "owned", source_vehicle: vehicle)

    assert_not second.valid?
    assert second.errors.of_kind?(:source_vehicle_id, :taken)
  end

  test "an owned route starts on its ship's model whatever was sent" do
    vehicle = create(:vehicle, user: @user, model: @carrack)

    acquisition = create_acquisition(start_kind: "owned", source_vehicle: vehicle, start_model: @cutlass)

    assert_equal @carrack, acquisition.start_model
  end

  test "a route whose ship left the hangar can still be edited" do
    vehicle = create(:vehicle, user: @user, model: @carrack)
    acquisition = create_acquisition(start_kind: "owned", source_vehicle: vehicle)
    vehicle.destroy!

    assert acquisition.reload.update(price_override: 10)
  end

  test "a slot cannot drop below the routes it has" do
    @slot.update!(quantity: 2)
    2.times { create_acquisition(start_kind: "store", start_model: @carrack) }

    assert_not @slot.update(quantity: 1)
    assert @slot.errors.of_kind?(:quantity, :below_routes)
  end

  test "another user's ship cannot start a route" do
    vehicle = create(:vehicle, model: @carrack)

    acquisition = build_acquisition(start_kind: "owned", source_vehicle: vehicle)

    assert_not acquisition.valid?
    assert acquisition.errors.of_kind?(:source_vehicle_id, :invalid)
  end

  test "a melted ship cannot start a route, nor a route's ship be melted" do
    melted = create(:vehicle, user: @user, model: @carrack)
    kept = create(:vehicle, user: @user, model: @carrack)
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle: melted)
    create_acquisition(start_kind: "owned", source_vehicle: kept)
    @slot.update!(quantity: 2)

    acquisition = build_acquisition(start_kind: "owned", source_vehicle: melted)
    melt = build(:hangar_plan_melt, hangar_plan: @plan, vehicle: kept)

    assert acquisition.errors.of_kind?(:source_vehicle_id, :melted) unless acquisition.valid?
    assert_not melt.valid?
    assert melt.errors.of_kind?(:vehicle_id, :taken)
  end

  test "a slot takes no more routes than its quantity" do
    create_acquisition(start_kind: "store", start_model: @carrack)

    acquisition = build_acquisition(start_kind: "store", start_model: @carrack)

    assert_not acquisition.valid?
    assert acquisition.errors.of_kind?(:base, :slot_filled)
  end

  test "a route has to end on the slot's ship" do
    acquisition = build_acquisition(start_kind: "store", start_model: @cutlass)

    assert_not acquisition.valid?
    assert acquisition.errors.of_kind?(:base, :chain_mismatch)
  end

  test "each upgrade starts where the one before ended" do
    acquisition = build_acquisition(start_kind: "store", start_model: @cutlass)
    acquisition.upgrade_steps.build(source_kind: "store", origin_model: @constellation, target_model: @carrack, position: 0)

    assert_not acquisition.valid?
    assert acquisition.errors.of_kind?(:base, :chain_broken)
  end

  test "an upgrade held once cannot be spent by two steps of one chain" do
    ccu = create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Cutlass To Carrack", quantity: 1)
    other = create(:model, pledge_price: 400)
    acquisition = build_acquisition(start_kind: "store", start_model: @cutlass)
    acquisition.upgrade_steps.build(source_kind: "owned_ccu", hangar_pledge_item: ccu, origin_model: @cutlass, target_model: other, position: 0)
    acquisition.upgrade_steps.build(source_kind: "owned_ccu", hangar_pledge_item: ccu, origin_model: other, target_model: @carrack, position: 1)

    assert_not acquisition.valid?
    assert acquisition.errors.of_kind?(:base, :upgrade_taken)
  end

  test "an upgrade held twice can be spent twice across the plan" do
    ccu = create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Cutlass To Carrack", quantity: 2)
    @slot.update!(quantity: 3)

    2.times do
      acquisition = build_acquisition(start_kind: "store", start_model: @cutlass)
      acquisition.upgrade_steps.build(source_kind: "owned_ccu", hangar_pledge_item: ccu, origin_model: @cutlass, target_model: @carrack, position: 0)
      acquisition.save!
    end

    third = build_acquisition(start_kind: "store", start_model: @cutlass)
    third.upgrade_steps.build(source_kind: "owned_ccu", hangar_pledge_item: ccu, origin_model: @cutlass, target_model: @carrack, position: 0)

    assert_not third.valid?
  end

  test "a buy-back pledge is spent once" do
    pledge = create(:buyback_pledge, user: @user)
    @slot.update!(quantity: 2)
    create_acquisition(start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)

    second = build_acquisition(start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)

    assert_not second.valid?
    assert second.errors.of_kind?(:buyback_pledge_id, :taken)
  end

  test "an upgrade buy-back cannot start a route" do
    pledge = create(:buyback_pledge, user: @user, kind: "upgrade")

    acquisition = build_acquisition(start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)

    assert_not acquisition.valid?
    assert acquisition.errors.of_kind?(:buyback_pledge_id, :invalid)
  end

  test "planning never changes the live hangar" do
    vehicle = create(:vehicle, user: @user, model: @carrack)
    melted = create(:vehicle, user: @user, model: @cutlass)

    assert_no_changes -> { Vehicle.order(:id).pluck(:id, :model_id, :updated_at) } do
      create_acquisition(start_kind: "owned", source_vehicle: vehicle)
      create(:hangar_plan_melt, hangar_plan: @plan, vehicle: melted)
      @plan.destroy!
    end
  end

  private def build_acquisition(**attributes)
    @plan.acquisitions.new(candidate: @candidate, **attributes)
  end

  private def create_acquisition(**attributes)
    build_acquisition(**attributes).tap(&:save!)
  end
end
