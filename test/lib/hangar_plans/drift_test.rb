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

  test "a price change shows the old and the new total" do
    slot = @plan.slots.create!(label: "Carrack")
    candidate = slot.candidates.create!(model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: @carrack)
    @carrack.update_columns(pledge_price: 650)

    drift = HangarPlans::Drift.new(@plan.reload)

    assert_equal [600, 650], [drift.previous_total, drift.current_total]
    assert_predicate drift, :drifted?
  end

  test "a rebase adds new ships, keeps edits and takes prices again" do
    slot = @plan.slots.create!(label: "Carrack")
    candidate = slot.candidates.create!(model: @carrack)
    @plan.acquisitions.create!(candidate:, start_kind: "store", start_model: @carrack, price_override: 500)
    @carrack.update_columns(pledge_price: 650)

    travel 1.minute do
      create(:vehicle, user: @user, model: @carrack)
      HangarPlans::Drift.new(@plan).rebase!
    end

    @plan.reload
    assert_equal 2, @plan.acquisitions.where(start_model: @carrack).count
    assert_equal 500, @plan.acquisitions.find_by(start_kind: "store").price_override
    assert_not HangarPlans::Drift.new(@plan).drifted?
  end
end
