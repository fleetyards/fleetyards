# frozen_string_literal: true

require "test_helper"

class HangarPlans::SummaryTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @plan = create(:hangar_plan, user: @user, starting_credit: 50)
    @cutlass = create(:model, name: "Cutlass Black", pledge_price: 100, on_sale: true)
    @constellation = create(:model, name: "Constellation Andromeda", pledge_price: 250, on_sale: true)
    @carrack = create(:model, name: "Carrack", pledge_price: 600, on_sale: true)
  end

  test "a store purchase costs the store price and an in-game one costs nothing" do
    bought = decided_slot(@carrack)
    @plan.acquisitions.create!(candidate: bought, start_kind: "store", start_model: @carrack)
    earned = decided_slot(@cutlass)
    @plan.acquisitions.create!(candidate: earned, start_kind: "ingame", start_model: @cutlass)

    summary = HangarPlans::Summary.new(@plan)

    assert_equal 600, summary.spend_min
    assert_equal 600, summary.spend_max
    assert_predicate summary, :complete?
  end

  test "an upgrade costs the difference between both store prices, and one already held nothing" do
    store = decided_slot(@carrack)
    route = @plan.acquisitions.new(candidate: store, start_kind: "store", start_model: @cutlass)
    route.upgrade_steps.build(source_kind: "store", origin_model: @cutlass, target_model: @constellation, position: 0)
    route.upgrade_steps.build(source_kind: "store", origin_model: @constellation, target_model: @carrack, position: 1)
    route.save!

    held = decided_slot(@constellation)
    ccu = create(:hangar_pledge_item, user: @user, kind: "ccu", name: "Upgrade - Cutlass Black To Constellation Andromeda")
    owned = create(:vehicle, user: @user, model: @cutlass)
    chain = @plan.acquisitions.new(candidate: held, start_kind: "owned", source_vehicle: owned)
    chain.upgrade_steps.build(source_kind: "owned_ccu", hangar_pledge_item: ccu, origin_model: @cutlass, target_model: @constellation, position: 0)
    chain.save!

    # 100 for the Cutlass, 150 and 350 for the upgrades; the held chain is free.
    assert_equal 600, HangarPlans::Summary.new(@plan).spend_min
  end

  test "a buy-back costs what RSI asks for it, and an override wins" do
    candidate = decided_slot(@carrack, quantity: 2)
    pledge = create(:buyback_pledge, user: @user, price: 550)
    @plan.acquisitions.create!(candidate:, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: @carrack, price_override: 480)

    assert_equal 1030, HangarPlans::Summary.new(@plan).spend_min
  end

  test "an unknown price is reported rather than counted as free" do
    concept = create(:model, name: "Concept", pledge_price: nil)
    candidate = decided_slot(concept)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: concept)

    summary = HangarPlans::Summary.new(@plan)

    assert_equal 0, summary.spend_min
    assert_not summary.complete?
    assert_includes summary.issues.map(&:kind), "missing_price"
    assert_includes summary.issues.map(&:name), "Concept"
  end

  test "a store purchase of a ship off sale is flagged" do
    retired = create(:model, name: "Retired", pledge_price: 300, on_sale: false)
    candidate = decided_slot(retired)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: retired)

    issue = HangarPlans::Summary.new(@plan).issues.find { |entry| entry.kind == "not_on_sale" }

    assert_equal "Retired", issue&.name
  end

  test "units without a route are gaps, not assumed purchases" do
    decided_slot(@carrack, quantity: 3)
    create(:hangar_plan_slot, hangar_plan: @plan, quantity: 2)

    summary = HangarPlans::Summary.new(@plan)

    assert_equal 0, summary.spend_max
    assert_equal 5, summary.unresolved_count
    assert_equal 1, summary.count_of("open")
  end

  test "an undecided slot costs between its cheapest and dearest candidate, less ships already held" do
    slot = create(:hangar_plan_slot, hangar_plan: @plan, quantity: 2)
    create(:hangar_plan_candidate, slot:, model: @cutlass)
    create(:hangar_plan_candidate, slot:, model: @carrack)
    create(:vehicle, user: @user, model: @carrack)

    summary = HangarPlans::Summary.new(@plan)

    assert_equal 200, summary.spend_min
    assert_equal 600, summary.spend_max
    assert_not summary.complete?
  end

  test "melts credit today's price unless overridden, and credit pays first" do
    candidate = decided_slot(@carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: @carrack)
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle: create(:vehicle, user: @user, model: @constellation))
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle: create(:vehicle, user: @user, model: @cutlass), value_override: 80)

    summary = HangarPlans::Summary.new(@plan)

    assert_equal 330, summary.melt_credit
    assert_equal 1, summary.estimated_melts_count
    assert_equal 270, summary.net_min
    assert_equal 220, summary.cash_needed_min
    assert_equal 0, summary.remaining_credit_max
  end

  test "extras add to a purchase but not to a ship already held" do
    paint = create(:model_paint, model: @carrack, pledge_price: 20)
    candidate = decided_slot(@carrack, quantity: 2)
    candidate.update!(model_paint: paint)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "owned", source_vehicle: create(:vehicle, user: @user, model: @carrack))

    assert_equal 620, HangarPlans::Summary.new(@plan).spend_min
  end

  private def decided_slot(model, quantity: 1)
    slot = create(:hangar_plan_slot, hangar_plan: @plan, quantity:)
    create(:hangar_plan_candidate, slot:, model:)
  end
end
