# frozen_string_literal: true

require "test_helper"

class HangarPlans::KeepTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @plan = create(:hangar_plan, user: @user)
    @gladius = create(:model, name: "Gladius", pledge_price: 90)
  end

  test "a kept ship needs no slot and stays" do
    vehicle = create(:vehicle, user: @user, model: @gladius)
    @plan.vehicle_marks.create!(vehicle:, mark: "change")

    HangarPlans::Keep.new(@plan).run([vehicle])

    assert_empty @plan.slots
    assert_equal [[vehicle.id, "keep"]], @plan.vehicle_marks.pluck(:vehicle_id, :mark)

    comparison = HangarPlans::Comparison.new(@plan)
    assert_equal ["kept"], comparison.vehicles.map(&:status)
    assert_equal [[1, 1]], comparison.models.map { |diff| [diff.left_count, diff.right_count] }
  end

  test "a kept ship fills an open unit of its model rather than counting twice" do
    vehicle = create(:vehicle, user: @user, model: @gladius)
    @plan.slots.create!(label: "Fighter").candidates.create!(model: @gladius)

    HangarPlans::Keep.new(@plan).run([vehicle])

    assert_equal [[1, 1]], HangarPlans::Comparison.new(@plan).models.map { |diff| [diff.left_count, diff.right_count] }
  end
end
