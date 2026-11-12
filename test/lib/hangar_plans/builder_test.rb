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

  test "a plan from the wishlist has a slot for each ship to obtain, alike ships side by side" do
    create(:vehicle, user: @user, model: @carrack, wanted: true)
    create(:vehicle, user: @user, model: @gladius, wanted: true)
    create(:vehicle, user: @user, model: @carrack, wanted: true)

    plan = build_plan("wishlist")

    assert_equal [@carrack.id, @carrack.id, @gladius.id], plan.slots.map { |slot| slot.candidates.first.model_id }
    assert_empty plan.acquisitions
  end

  test "a duplicate copies slots, candidates, routes, melts and marks" do
    gladii = create_list(:vehicle, 2, user: @user, model: @gladius)
    create(:vehicle, user: @user, model: @carrack)
    source = build_plan("hangar")
    HangarPlanVehicleMark.write(source, gladii, "keep", overwrite: true)
    create(:hangar_plan_melt, hangar_plan: source, vehicle: create(:vehicle, user: @user, model: @carrack))
    open_slot = source.slots.create!(label: "Hauler")
    open_slot.candidates.create!(model: @carrack)
    open_slot.candidates.create!(model: @gladius)
    waiting_slot = source.slots.create!(label: "Fighter")
    source.acquisitions.create!(slot: waiting_slot, start_kind: "store")

    copy = build_plan("plan", source_plan: source)

    assert_equal ["store"], copy.slots.find_by(label: "Fighter").starts.pluck(:start_kind)

    assert_equal source.slots.map { |slot| [slot.label, slot.state] }, copy.slots.map { |slot| [slot.label, slot.state] }
    assert_equal source.acquisitions.pluck(:source_vehicle_id).sort, copy.acquisitions.pluck(:source_vehicle_id).sort
    assert_equal source.melts.pluck(:vehicle_id), copy.melts.pluck(:vehicle_id)
    assert_equal source.vehicle_marks.pluck(:vehicle_id, :mark).sort, copy.vehicle_marks.pluck(:vehicle_id, :mark).sort
  end

  test "a duplicate keeps a bundled start with the copy of its pledge's start" do
    source = build_plan("empty")
    pledge = create(:buyback_pledge, user: @user, kind: "package", name: "Package - Duo", ship_names: ["Carrack", "Gladius"])
    gladius = source.slots.create!(label: "Fighter").candidates.create!(model: @gladius)
    carrack = source.slots.create!(label: "Explorer").candidates.create!(model: @carrack)
    pledge_start = source.acquisitions.create!(candidate: carrack, start_kind: "buyback", buyback_pledge: pledge, start_model: @carrack)
    source.acquisitions.create!(candidate: gladius, start_kind: "bundled", bundled_with: pledge_start, start_model: @gladius)

    copy = build_plan("plan", source_plan: source)

    bundled = copy.acquisitions.find_by!(start_kind: "bundled")
    assert_equal copy.acquisitions.find_by!(start_kind: "buyback"), bundled.bundled_with
  end

  test "a plan from a wishlist bigger than the slot limit is not built" do
    create_list(:vehicle, 3, user: @user, model: @gladius, wanted: true)

    stub_const(HangarPlanSlot, :MAX_PER_PLAN, 2) do
      assert_no_difference -> { HangarPlan.count } do
        error = assert_raises(ActiveRecord::RecordInvalid) { build_plan("wishlist") }
        assert error.record.errors.of_kind?(:base, :wishlist_too_large)
      end
    end
  end

  test "a duplicate of a plan already over the slot limit copies every slot" do
    source = build_plan("empty")
    3.times { |index| source.slots.create!(label: "Fighter #{index}") }

    stub_const(HangarPlanSlot, :MAX_PER_PLAN, 2) do
      assert_equal 3, build_plan("plan", source_plan: source).slots.count
    end
  end

  private def build_plan(source, source_plan: nil)
    plan = @user.hangar_plans.new(name: "Plan #{SecureRandom.hex(3)}")
    HangarPlans::Builder.new(plan, source:, source_plan:).run
  end
end
