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
    pairs.map { |slot, mod| {slot_path: slot, item_type: "ModelModule", item_id: mod.id} }
  end

  def fleetyards_loadout(items)
    VehicleLoadout.new(vehicle: @vehicle, kind: "fleetyards", item_list: items)
  end

  test "fits one module into each slot" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo], ["hardpoint_rear_module", @rear_cargo]))

    assert loadout.save, loadout.errors.full_messages.to_sentence
    assert_equal [@front_cargo.id, @rear_cargo.id], loadout.items.pluck(:item_id)
    assert_equal "Fleetyards Loadout", loadout.name
  end

  test "refuses a second module in the same slot" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo], ["hardpoint_front_module", @front_torpedo]))

    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, :slot_taken)
  end

  test "fits a module the ship does not own: a loadout is a plan" do
    @vehicle.vehicle_modules.destroy_all
    @vehicle.reload

    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_torpedo]))

    assert loadout.save, loadout.errors.full_messages.to_sentence
  end

  test "refuses a module in a slot it does not fit, or one with no known slot" do
    wrong_slot = fleetyards_loadout(fit(["hardpoint_rear_module", @front_cargo]))
    unslotted = fleetyards_loadout(fit(["hardpoint_front_module", @unslotted]))

    assert_not wrong_slot.save
    assert wrong_slot.errors.of_kind?(:items, :module_not_in_slot)
    assert_not unslotted.save
    assert unslotted.errors.of_kind?(:items, :module_not_in_slot)
  end

  test "refuses a slot inside one that is not fitted" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo]) + [
      {slot_path: "hardpoint_rear_module/hardpoint_turret", item_type: "ModelModule", item_id: @rear_cargo.id}
    ])

    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, :parent_not_fitted)
  end

  test "refuses anything but a module for now" do
    loadout = fleetyards_loadout([{slot_path: "hardpoint_weapon", item_type: "Component", item_id: SecureRandom.uuid}])

    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, :item_type_not_supported)
  end

  test "a module removed from the catalogue is unfitted with what sat inside it" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo], ["hardpoint_rear_module", @rear_cargo]))
    loadout.save!
    loadout.items.create!(slot_path: "hardpoint_front_module/hardpoint_turret", item: @rear_cargo)

    @front_cargo.destroy!

    assert_equal ["hardpoint_rear_module"], loadout.reload.items.pluck(:slot_path)
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

    assert_equal [@front_torpedo.id], loadout.reload.items.pluck(:item_id)
  end

  test "emptying the fitting touches the loadout and the vehicle" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo]))
    loadout.save!

    travel 1.minute do
      loadout.update!(item_list: [])

      assert_empty loadout.reload.items
      assert_in_delta Time.current, loadout.updated_at, 1.second
      assert_in_delta Time.current, @vehicle.reload.updated_at, 1.second
    end
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
