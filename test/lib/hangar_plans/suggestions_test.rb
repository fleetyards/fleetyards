# frozen_string_literal: true

require "test_helper"

class HangarPlans::SuggestionsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @plan = create(:hangar_plan, user: @user)
    @cutlass = create(:model, name: "Cutlass Black", pledge_price: 100, classification: "transport", size: "medium", foci: %w[freight])
    @freelancer = create(:model, name: "Freelancer", pledge_price: 125, classification: "transport", size: "medium", foci: %w[freight])
    @carrack = create(:model, name: "Carrack", pledge_price: 600, classification: "exploration", size: "large", foci: %w[expedition])
    @gladius = create(:model, name: "Gladius", pledge_price: 90, classification: "combat", size: "small", foci: %w[light_fighter])
  end

  test "a model the planned hangar holds twice is a duplicate" do
    create(:vehicle, user: @user, model: @gladius)
    create(:vehicle, user: @user, model: @gladius)

    duplicate = redundancies.find { |entry| entry.kind == "duplicate" }

    assert_equal @gladius, duplicate.model
    assert_equal 2, duplicate.entries.size
    assert(duplicate.entries.all? { |entry| entry.vehicle.present? && entry.slot.nil? })
  end

  test "two models of one role are redundant, a slot's unit among them" do
    create(:vehicle, user: @user, model: @cutlass)
    slot = create(:hangar_plan_slot, hangar_plan: @plan, label: "Hauler")
    create(:hangar_plan_candidate, slot:, model: @freelancer)

    role = redundancies.sole

    assert_equal "role", role.kind
    assert_equal %w[transport medium freight], [role.classification, role.size, role.focus]
    assert_equal ["Cutlass Black", "Freelancer"], role.entries.map { |entry| entry.model.name }
    assert_equal slot, role.entries.last.slot
  end

  test "a ship the plan melts or upgrades away no longer counts" do
    melted = create(:vehicle, user: @user, model: @cutlass)
    upgraded = create(:vehicle, user: @user, model: @freelancer)
    create(:vehicle, user: @user, model: @freelancer)
    create(:hangar_plan_melt, hangar_plan: @plan, vehicle: melted)
    slot = create(:hangar_plan_slot, hangar_plan: @plan)
    candidate = create(:hangar_plan_candidate, slot:, model: @carrack)
    route = @plan.acquisitions.new(candidate:, start_kind: "owned", source_vehicle: upgraded)
    route.upgrade_steps.build(source_kind: "store", origin_model: @freelancer, target_model: @carrack, position: 0)
    route.save!

    assert_empty redundancies
  end

  private def redundancies
    HangarPlans::Suggestions.new(@plan).redundancies
  end
end
