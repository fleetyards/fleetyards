# frozen_string_literal: true

require "test_helper"

class HangarPlanVehicleMarkTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @plan = create(:hangar_plan, user: @user)
    @gladius = create(:model, name: "Gladius", pledge_price: 90)
  end

  test "a kept ship needs no slot and stays" do
    vehicle = create(:vehicle, user: @user, model: @gladius)
    @plan.vehicle_marks.create!(vehicle:, mark: "change")

    HangarPlanVehicleMark.write(@plan, [vehicle], "keep", overwrite: true)

    assert_empty @plan.slots
    assert_equal [[vehicle.id, @gladius.id, "keep"]], @plan.vehicle_marks.pluck(:vehicle_id, :model_id, :mark)

    comparison = HangarPlans::Comparison.new(@plan)
    assert_equal ["kept"], comparison.vehicles.map(&:status)
    assert_equal [[1, 1]], comparison.models.map { |diff| [diff.left_count, diff.right_count] }
  end

  test "a write without overwrite leaves a ship's mark alone" do
    vehicle = create(:vehicle, user: @user, model: @gladius)
    @plan.vehicle_marks.create!(vehicle:, mark: "keep")

    HangarPlanVehicleMark.write(@plan, [vehicle], "pending")

    assert_equal ["keep"], @plan.vehicle_marks.pluck(:mark)
  end

  test "a kept ship fills an open unit of its model rather than counting twice" do
    vehicle = create(:vehicle, user: @user, model: @gladius)
    @plan.slots.create!(label: "Fighter").candidates.create!(model: @gladius)

    HangarPlanVehicleMark.write(@plan, [vehicle], "keep", overwrite: true)

    assert_equal [[1, 1]], HangarPlans::Comparison.new(@plan).models.map { |diff| [diff.left_count, diff.right_count] }
  end

  test "a ship of a melted pledge cannot be kept, and a kept one stops its pledge melting" do
    melted = create(:vehicle, user: @user, model: @gladius, rsi_pledge_id: "pack")
    sibling = create(:vehicle, user: @user, model: @gladius, rsi_pledge_id: "pack")
    @plan.melts.create!(vehicle: melted)

    mark = @plan.vehicle_marks.build(vehicle: sibling, mark: "keep")
    assert_not mark.valid?
    assert_includes mark.errors.details[:vehicle_id], {error: :pledge_melted}

    @plan.melts.destroy_all
    @plan.vehicle_marks.create!(vehicle: sibling, mark: "keep")
    melt = @plan.melts.build(vehicle: melted)
    assert_not melt.valid?
    assert_includes melt.errors.details[:vehicle_id], {error: :pledge_kept}
  end
end
