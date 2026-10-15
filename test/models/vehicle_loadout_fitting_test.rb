# frozen_string_literal: true

require "test_helper"

class VehicleLoadoutFittingTest < ActiveSupport::TestCase
  setup do
    @model = create(:model, production_status: "flight-ready")
    @front_cargo = create(:model_module, name: "Front Cargo Module")
    @front_torpedo = create(:model_module, name: "Front Torpedo Bay")
    @rear_cargo = create(:model_module, name: "Rear Cargo Module")
    @unslotted = create(:model_module, name: "Mystery Module")
    create(:module_hardpoint, model: @model, model_module: @front_cargo, slot: "hardpoint_front_module")
    create(:module_hardpoint, model: @model, model_module: @front_torpedo, slot: "hardpoint_front_module")
    create(:module_hardpoint, model: @model, model_module: @rear_cargo, slot: "hardpoint_rear_module")
    create(:module_hardpoint, model: @model, model_module: @unslotted, slot: nil)

    @vehicle = create(:vehicle, model: @model,
      model_module_ids: [@front_cargo, @front_torpedo, @rear_cargo, @unslotted].map(&:id))
  end

  def fit(*pairs)
    pairs.map { |slot, mod| {slot:, model_module_id: mod.id} }
  end

  def fleetyards_loadout(items)
    @vehicle.vehicle_loadouts.new(kind: "fleetyards", item_list: items)
  end

  test "fits one owned module into each slot" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo], ["hardpoint_rear_module", @rear_cargo]))

    assert loadout.save, loadout.errors.full_messages.to_sentence
    assert_equal [@front_cargo.id, @rear_cargo.id], loadout.items.pluck(:model_module_id)
    assert_equal "Fleetyards Loadout", loadout.name
  end

  test "refuses a second module in the same slot" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo], ["hardpoint_front_module", @front_torpedo]))

    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, :slot_taken)
  end

  test "refuses a module the ship does not own" do
    @vehicle.update!(model_module_ids: [@rear_cargo.id])
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo]))

    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, :module_not_owned)
  end

  test "refuses a module in a slot it does not fit, or one with no known slot" do
    wrong_slot = fleetyards_loadout(fit(["hardpoint_rear_module", @front_cargo]))
    unslotted = fleetyards_loadout(fit(["hardpoint_front_module", @unslotted]))

    assert_not wrong_slot.save
    assert wrong_slot.errors.of_kind?(:items, :module_not_in_slot)
    assert_not unslotted.save
    assert unslotted.errors.of_kind?(:items, :module_not_in_slot)
  end

  test "a link carries no items and a fleetyards loadout no url" do
    link = @vehicle.vehicle_loadouts.new(url: "https://erkul.games/loadout/x",
      item_list: fit(["hardpoint_rear_module", @rear_cargo]))
    with_url = @vehicle.vehicle_loadouts.new(kind: "fleetyards", url: "https://erkul.games/loadout/x")

    assert_not link.save
    assert link.errors.of_kind?(:items, :not_fleetyards)
    assert_not with_url.save
    assert with_url.errors.of_kind?(:url, :present)
  end

  test "a ship that is not flight-ready cannot get a loadout of either kind" do
    @model.update!(production_status: "in-concept")

    assert_not @vehicle.vehicle_loadouts.new(kind: "fleetyards").save
    assert_not @vehicle.vehicle_loadouts.new(url: "https://erkul.games/loadout/x").save
  end

  test "saving a new fitting replaces the old one" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo]))
    loadout.save!

    loadout.update!(item_list: fit(["hardpoint_front_module", @front_torpedo]))

    assert_equal [@front_torpedo.id], loadout.reload.items.pluck(:model_module_id)
  end

  test "a module that leaves the hangar is unfitted" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo], ["hardpoint_rear_module", @rear_cargo]))
    loadout.save!

    @vehicle.update!(model_module_ids: [@rear_cargo.id])
    @vehicle.unfit_unowned_modules

    assert_equal [@rear_cargo.id], loadout.reload.items.pluck(:model_module_id)
  end

  test "activating a fleetyards loadout switches off an active link" do
    link = @vehicle.vehicle_loadouts.create!(url: "https://erkul.games/loadout/x", active: true)
    loadout = fleetyards_loadout([])
    loadout.save!

    loadout.activate!

    assert_not link.reload.active
    assert loadout.reload.active
  end
end
