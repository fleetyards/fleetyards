# frozen_string_literal: true

require "test_helper"

class HangarPlans::BuilderTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @gladius = create(:model, name: "Gladius", pledge_price: 90, production_status: "flight-ready")
    @carrack = create(:model, name: "Carrack", pledge_price: 600, size: "large")
  end

  test "a plan from the hangar leaves each purchased ship to decide" do
    gladii = create_list(:vehicle, 3, user: @user, model: @gladius)
    carrack = create(:vehicle, user: @user, model: @carrack)
    create(:vehicle, user: @user, model: @carrack, wanted: true)
    create(:vehicle, user: @user, model: @carrack, loaner: true)
    create(:vehicle, user: @user, model: @gladius, bundled: true)

    plan = build_plan("hangar")

    assert_empty plan.slots
    assert_empty plan.acquisitions
    assert_equal [*gladii, carrack].map(&:id).sort, plan.vehicle_marks.pluck(:vehicle_id).sort
    assert_equal ["pending"], plan.vehicle_marks.distinct.pluck(:mark)
    assert_equal ["pending"], HangarPlans::Comparison.new(plan).vehicles.map(&:status).uniq
  end

  test "a plan from the wishlist has its ships to obtain" do
    create(:vehicle, user: @user, model: @carrack, wanted: true)

    plan = build_plan("wishlist")

    assert_equal [@carrack.id], plan.candidates.pluck(:model_id)
    assert_empty plan.acquisitions
  end

  test "a duplicate copies slots, candidates, routes, melts and marks" do
    gladii = create_list(:vehicle, 2, user: @user, model: @gladius)
    create(:vehicle, user: @user, model: @carrack)
    source = build_plan("hangar")
    HangarPlans::Keep.new(source).run(gladii)
    create(:hangar_plan_melt, hangar_plan: source, vehicle: create(:vehicle, user: @user, model: @carrack))
    open_slot = source.slots.create!(label: "Hauler", quantity: 2)
    open_slot.candidates.create!(model: @carrack)
    open_slot.candidates.create!(model: @gladius)

    copy = build_plan("plan", source_plan: source)

    assert_equal source.slots.map { |slot| [slot.label, slot.quantity, slot.state] },
      copy.slots.map { |slot| [slot.label, slot.quantity, slot.state] }
    assert_equal source.acquisitions.pluck(:source_vehicle_id).sort, copy.acquisitions.pluck(:source_vehicle_id).sort
    assert_equal source.melts.pluck(:vehicle_id), copy.melts.pluck(:vehicle_id)
    assert_equal source.vehicle_marks.pluck(:vehicle_id, :mark).sort, copy.vehicle_marks.pluck(:vehicle_id, :mark).sort
  end

  private def build_plan(source, source_plan: nil)
    plan = @user.hangar_plans.new(name: "Plan #{SecureRandom.hex(3)}")
    HangarPlans::Builder.new(plan, source:, source_plan:).run
  end
end
