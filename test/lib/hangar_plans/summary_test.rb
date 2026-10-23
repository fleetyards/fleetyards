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

  test "a plan without slots is not complete" do
    assert_not HangarPlans::Summary.new(@plan).complete?
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
    assert_equal 3, summary.unresolved_count
    assert_equal 1, summary.count_of("open")
    assert_not summary.complete?
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

  test "a ship held once covers one undecided slot, not every one" do
    create(:vehicle, user: @user, model: @cutlass)
    2.times do
      slot = create(:hangar_plan_slot, hangar_plan: @plan)
      create(:hangar_plan_candidate, slot:, model: @cutlass)
      create(:hangar_plan_candidate, slot:, model: @carrack)
    end

    assert_equal 100, HangarPlans::Summary.new(@plan).spend_min
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

  test "a buy-back is paid in new money unless it spends a token the user holds" do
    @plan.update!(starting_credit: 1000)
    candidate = decided_slot(@carrack, quantity: 2)
    pledge = create(:buyback_pledge, user: @user, price: 550)
    @plan.acquisitions.create!(candidate:, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack,
      uses_buyback_token: true)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: @carrack)

    summary = HangarPlans::Summary.new(@plan)

    # Marked, but no token held: the store Carrack takes 600 of the credit and
    # the buy-back cannot take any.
    assert_equal 1, summary.buyback_tokens_used
    assert_equal 0, summary.buyback_tokens_available
    assert_equal 550, summary.buyback_cash
    assert_equal 550, summary.cash_needed_min
    assert_equal 400, summary.remaining_credit_min

    @plan.update!(buyback_tokens: 1)
    summary = HangarPlans::Summary.new(@plan)

    assert_equal 0, summary.buyback_cash
    assert_equal 150, summary.cash_needed_min
  end

  test "a buy-back the user does not mark stays new money with tokens to spare" do
    @plan.update!(starting_credit: 1000, buyback_tokens: 2)
    candidate = decided_slot(@carrack)
    pledge = create(:buyback_pledge, user: @user, price: 550)
    @plan.acquisitions.create!(candidate:, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)

    summary = HangarPlans::Summary.new(@plan)

    assert_equal 0, summary.buyback_tokens_used
    assert_equal 550, summary.buyback_cash
  end

  test "a plan without its own token count uses what the buy-back sync read" do
    @user.update!(rsi_buyback_tokens: 1)
    candidate = decided_slot(@carrack)
    pledge = create(:buyback_pledge, user: @user, price: 550)
    @plan.acquisitions.create!(candidate:, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack,
      uses_buyback_token: true)

    assert_equal 0, HangarPlans::Summary.new(@plan).buyback_cash

    @plan.update!(buyback_tokens: 0)
    assert_equal 550, HangarPlans::Summary.new(@plan.reload).buyback_cash
  end

  test "marked beyond the tokens held, the dearest buy-back keeps its token" do
    @plan.update!(starting_credit: 0, buyback_tokens: 1)
    candidate = decided_slot(@carrack, quantity: 2)
    dear = create(:buyback_pledge, user: @user, price: 550)
    cheap = create(:buyback_pledge, user: @user, price: 120)
    @plan.acquisitions.create!(candidate:, start_kind: "buyback", buyback_pledge: dear, start_model: @carrack,
      uses_buyback_token: true)
    @plan.acquisitions.create!(candidate:, start_kind: "buyback", buyback_pledge: cheap, start_model: @carrack,
      uses_buyback_token: true)

    summary = HangarPlans::Summary.new(@plan)

    assert_equal 2, summary.buyback_tokens_used
    assert_equal 120, summary.buyback_cash
    assert_equal 1, summary.buybacks_without_token_count
  end

  test "only a buy-back can spend a token" do
    candidate = decided_slot(@carrack)
    route = @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: @carrack, uses_buyback_token: true)

    assert_not route.uses_buyback_token
  end

  test "a melt credits what its pledge is worth, and falls back to the store price as an estimate" do
    synced = create(:vehicle, user: @user, model: @cutlass, rsi_pledge_id: "9", rsi_pledge_melt_value: 90, rsi_pledge_meltable: true)
    by_hand = create(:vehicle, user: @user, model: @cutlass)
    @plan.melts.create!(vehicle: synced)
    @plan.melts.create!(vehicle: by_hand)

    summary = HangarPlans::Summary.new(@plan)

    assert_equal 190, summary.melt_credit
    assert_equal 1, summary.estimated_melts_count
  end

  test "two ships of one pledge credit the pledge once" do
    first = create(:vehicle, user: @user, model: @cutlass, rsi_pledge_id: "pack", rsi_pledge_melt_value: 300)
    second = create(:vehicle, user: @user, model: @constellation, rsi_pledge_id: "pack", rsi_pledge_melt_value: 300)
    @plan.melts.create!(vehicle: first)
    @plan.melts.create!(vehicle: second)

    summary = HangarPlans::Summary.new(@plan)
    assert_equal 300, summary.melt_credit
    assert_equal [300, 300], [summary.melt_credit_at, summary.melt_credit_at(snapshot: true)]
  end

  private def decided_slot(model, quantity: 1)
    slot = create(:hangar_plan_slot, hangar_plan: @plan, quantity:)
    create(:hangar_plan_candidate, slot:, model:)
  end
end
