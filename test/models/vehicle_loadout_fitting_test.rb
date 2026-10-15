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

  test "fits one owned module into each slot" do
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

  test "refuses a module the ship does not own" do
    @vehicle.update!(model_module_ids: [@rear_cargo.id])
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo]))

    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, :module_not_owned)
  end

  test "fits one owned copy into one slot only" do
    both_sides = create(:model_module, name: "Side Module")
    create(:module_hardpoint, model: @model, model_module: both_sides, slot: "hardpoint_left_module")
    create(:module_hardpoint, model: @model, model_module: both_sides, slot: "hardpoint_right_module")
    @vehicle.update!(model_module_ids: [both_sides.id])

    loadout = fleetyards_loadout(fit(["hardpoint_left_module", both_sides], ["hardpoint_right_module", both_sides]))

    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, :module_not_owned)

    # Cleared first, as `VehiclesController#update` does: the ids writer keeps
    # one copy when asked to go from one to two of the same module.
    @vehicle.vehicle_modules.destroy_all
    @vehicle.reload
    @vehicle.update!(model_module_ids: [both_sides.id, both_sides.id])

    two_copies = fleetyards_loadout(fit(["hardpoint_left_module", both_sides], ["hardpoint_right_module", both_sides]))
    assert two_copies.save, two_copies.errors.details.inspect
  end

  test "refuses a module in a slot it does not fit, or one with no known slot" do
    wrong_slot = fleetyards_loadout(fit(["hardpoint_rear_module", @front_cargo]))
    unslotted = fleetyards_loadout(fit(["hardpoint_front_module", @unslotted]))

    assert_not wrong_slot.save
    assert wrong_slot.errors.of_kind?(:items, :module_not_in_slot)
    assert_not unslotted.save
    assert unslotted.errors.of_kind?(:items, :module_not_in_slot)
  end

  test "fits the hull's stock module without owning it, and keeps it fitted" do
    stock = create(:model_module, name: "Front Stock Module", sc_key: "AEGS_Front_Stock")
    create(:module_hardpoint, model: @model, model_module: stock, slot: "hardpoint_front_module")
    create(:hardpoint, parent: @model, source: :game_files, category: :module,
      sc_name: "hardpoint_front_module", component: create(:component, sc_key: "aegs_front_stock", category: "module", component_type: "Module"))
    @vehicle.vehicle_modules.destroy_all
    @vehicle.reload

    loadout = fleetyards_loadout(fit(["hardpoint_front_module", stock]))

    assert loadout.save, loadout.errors.full_messages.to_sentence
    assert_not_includes @vehicle.model_module_ids, stock.id

    @vehicle.unfit_unowned_modules

    assert_equal [stock.id], loadout.reload.items.pluck(:item_id)
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

  test "unfitting a module takes what was fitted inside it along" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo]))
    loadout.save!
    # Written past the validation, standing in for a component category.
    loadout.items.create!(slot_path: "hardpoint_front_module/hardpoint_turret", item: @rear_cargo)

    @vehicle.update!(model_module_ids: [@rear_cargo.id])
    @vehicle.unfit_unowned_modules

    assert_empty loadout.reload.items
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

  test "a module that leaves the hangar is unfitted" do
    loadout = fleetyards_loadout(fit(["hardpoint_front_module", @front_cargo], ["hardpoint_rear_module", @rear_cargo]))
    loadout.save!

    @vehicle.update!(model_module_ids: [@rear_cargo.id])
    @vehicle.unfit_unowned_modules

    assert_equal [@rear_cargo.id], loadout.reload.items.pluck(:item_id)
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
