# frozen_string_literal: true

require "test_helper"

class HangarPlans::BuilderTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @gladius = create(:model, name: "Gladius", pledge_price: 90, production_status: "flight-ready")
    @carrack = create(:model, name: "Carrack", pledge_price: 600, size: "large")
  end

  test "a plan from the hangar keeps each purchased ship, grouped by model" do
    gladii = create_list(:vehicle, 3, user: @user, model: @gladius)
    create(:vehicle, user: @user, model: @carrack)
    create(:vehicle, user: @user, model: @carrack, wanted: true)
    create(:vehicle, user: @user, model: @carrack, loaner: true)
    create(:vehicle, user: @user, model: @gladius, bundled: true)

    plan = build_plan("hangar")

    assert_equal 2, plan.slots.count
    gladius_slot = plan.slots.find_by(label: "Gladius")
    assert_equal 3, gladius_slot.quantity
    assert_equal "decided", gladius_slot.state
    assert_equal gladii.map(&:id).sort, plan.acquisitions.where(start_kind: "owned", start_model: @gladius).pluck(:source_vehicle_id).sort
  end

  test "a plan from the hangar yields the hangar's own metrics" do
    create_list(:vehicle, 2, user: @user, model: @gladius)
    create(:vehicle, user: @user, model: @carrack)
    plan = build_plan("hangar")

    assert_equal HangarPlans::Metrics.for(HangarPlans::Metrics.live_models(plan)),
      HangarPlans::Metrics.for(HangarPlans::Metrics.plan_models(plan))
  end

  test "ships fitted differently stay apart" do
    paint = create(:model_paint, model: @gladius)
    create(:vehicle, user: @user, model: @gladius)
    painted = create(:vehicle, user: @user, model: @gladius)
    painted.vehicle_paints.create!(model_paint: paint)

    plan = build_plan("hangar")

    assert_equal 2, plan.slots.count
    assert_equal [nil, paint.id].to_set, plan.candidates.pluck(:model_paint_id).to_set
  end

  test "a plan from the wishlist has its ships to obtain" do
    create(:vehicle, user: @user, model: @carrack, wanted: true)

    plan = build_plan("wishlist")

    assert_equal [@carrack.id], plan.candidates.pluck(:model_id)
    assert_empty plan.acquisitions
  end

  test "a duplicate copies slots, candidates, routes and melts" do
    source = build_plan("hangar")
    create(:hangar_plan_melt, hangar_plan: source, vehicle: create(:vehicle, user: @user, model: @carrack))
    open_slot = source.slots.create!(label: "Hauler", quantity: 2)
    open_slot.candidates.create!(model: @carrack)
    open_slot.candidates.create!(model: @gladius)

    copy = build_plan("plan", source_plan: source)

    assert_equal source.slots.map { |slot| [slot.label, slot.quantity, slot.state] },
      copy.slots.map { |slot| [slot.label, slot.quantity, slot.state] }
    assert_equal source.acquisitions.pluck(:source_vehicle_id).sort, copy.acquisitions.pluck(:source_vehicle_id).sort
    assert_equal source.melts.pluck(:vehicle_id), copy.melts.pluck(:vehicle_id)
  end

  private def build_plan(source, source_plan: nil)
    plan = @user.hangar_plans.new(name: "Plan #{SecureRandom.hex(3)}")
    HangarPlans::Builder.new(plan, source:, source_plan:).run
  end
end
