# frozen_string_literal: true

require "test_helper"

class VehicleLoadoutComponentFittingTest < ActiveSupport::TestCase
  setup do
    @model = create(:model, production_status: "flight-ready")
    @vehicle = create(:vehicle, model: @model)

    @plant = create(:component, component_type: "PowerPlant", category: "powerplant", size: "1")
    @big_plant = create(:component, component_type: "PowerPlant", category: "powerplant", size: "2")
    @life_support = create(:component, component_type: "LifeSupportGenerator", category: "lifesupport", size: "1")
    @cooler = create(:component, component_type: "Cooler", category: "cooler", size: "1")
    @gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "3")
    @small_gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "2")
    @big_gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "4")

    # A mount and the gun port it offers, with the ship's own copy of that port
    # below the hull slot holding the gun it comes with.
    @gimbal = create(:component, component_type: "Turret", category: "weapon_mounts", size: "3")
    port(@gimbal, "hardpoint_class_2", types: ["WeaponGun"], min_size: 2, max_size: 3)
    @other_gimbal = create(:component, component_type: "Turret", category: "weapon_mounts", size: "3")
    port(@other_gimbal, "hardpoint_gun", types: ["WeaponGun"], min_size: 3, max_size: 3)

    port(@model, "hardpoint_power_plant", types: ["PowerPlant"], min_size: 1, max_size: 1, component: @plant)
    port(@model, "hardpoint_life_support", types: [], min_size: 1, max_size: 1, component: @life_support)
    nose = port(@model, "hardpoint_gun_nose", types: %w[Turret WeaponGun], min_size: 3, max_size: 3, component: @gimbal)
    port(nose, "hardpoint_class_2", min_size: 3, max_size: 3, component: @gun)
    locked = port(@model, "hardpoint_gun_wing", types: %w[Turret], min_size: 3, max_size: 3,
      component: @gimbal, flags: ["uneditable"])
    port(locked, "hardpoint_class_2", min_size: 3, max_size: 3, component: @gun)
    port(@model, "hardpoint_empty", types: ["Turret"], min_size: 3, max_size: 3)
  end

  def port(parent, name, **attributes)
    create(:hardpoint, parent:, sc_name: name, source: :game_files, **attributes)
  end

  def fit(*pairs)
    pairs.map { |slot, component| {slot_path: slot, item_type: "Component", item_id: component.id} }
  end

  def fleetyards_loadout(items)
    VehicleLoadout.new(vehicle: @vehicle, kind: "fleetyards", item_list: items)
  end

  def assert_refused(loadout, kind)
    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, kind), loadout.errors.details.inspect
  end

  test "fits a component whose type and size the slot takes" do
    loadout = fleetyards_loadout(fit(["hardpoint_power_plant", @plant]))

    assert loadout.save, loadout.errors.full_messages.to_sentence
    assert_equal [["Component", @plant.id]], loadout.items.pluck(:item_type, :item_id)
  end

  test "refuses a component of the wrong size or type" do
    assert_refused fleetyards_loadout(fit(["hardpoint_power_plant", @big_plant])), :component_not_in_slot
    assert_refused fleetyards_loadout(fit(["hardpoint_power_plant", @cooler])), :component_not_in_slot
  end

  test "matches a slot that names no types on its category" do
    assert fleetyards_loadout(fit(["hardpoint_life_support", @life_support])).save
    assert_refused fleetyards_loadout(fit(["hardpoint_life_support", @cooler])), :component_not_in_slot
  end

  test "matches a slot filed under a category its parts do not carry on the parts' type" do
    laser = create(:component, component_type: "WeaponMining", category: "weapons", size: "1")
    other_laser = create(:component, component_type: "WeaponMining", category: "weapons", size: "1")
    port(@model, "hardpoint_mining_laser", types: [], min_size: 1, max_size: 1, component: laser)

    assert_equal "mining_lasers", Hardpoint.find_by!(parent: @model, sc_name: "hardpoint_mining_laser").facts.category
    assert fleetyards_loadout(fit(["hardpoint_mining_laser", other_laser])).save
    assert_refused fleetyards_loadout(fit(["hardpoint_mining_laser", @small_gun])), :component_not_in_slot
  end

  test "fits a gun into the stock mount without fitting the mount" do
    loadout = fleetyards_loadout(fit(["hardpoint_gun_nose/hardpoint_class_2", @gun]))

    assert loadout.save, loadout.errors.full_messages.to_sentence
  end

  test "reads the size range of a port from the mount, not from the ship's copy" do
    assert fleetyards_loadout(fit(["hardpoint_gun_nose/hardpoint_class_2", @small_gun])).save
    assert_refused fleetyards_loadout(fit(["hardpoint_gun_nose/hardpoint_class_2", @big_gun])), :component_not_in_slot
  end

  test "a swapped mount brings its own ports" do
    loadout = fleetyards_loadout(fit(["hardpoint_gun_nose", @other_gimbal], ["hardpoint_gun_nose/hardpoint_gun", @gun]))
    stale = fleetyards_loadout(fit(["hardpoint_gun_nose", @other_gimbal], ["hardpoint_gun_nose/hardpoint_class_2", @gun]))

    assert loadout.save, loadout.errors.full_messages.to_sentence
    assert_refused stale, :slot_unknown
  end

  test "a tag a port above provides counts for what sits below it, not for the ship" do
    nose = Hardpoint.find_by!(parent: @model, sc_name: "hardpoint_gun_nose")
    nose.build.update!(port_tags: ["VanguardNose"])
    nose_gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "3",
      required_tags: ["VanguardNose"])
    Hardpoint.find_by!(parent: nose, sc_name: "hardpoint_class_2").build.update!(component: nose_gun)
    other_nose_gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "3",
      required_tags: ["VanguardNose"])

    assert fleetyards_loadout(fit(["hardpoint_gun_nose/hardpoint_class_2", other_nose_gun])).save
    assert_refused fleetyards_loadout(fit(["hardpoint_gun_wing/hardpoint_class_2", other_nose_gun])),
      :component_not_in_slot
  end

  test "a tag a stock mount's own port provides counts below it, not for the ship" do
    Hardpoint.find_by!(parent: @gimbal, sc_name: "hardpoint_class_2").build.update!(port_tags: ["Merlin_Nose"])
    merlin_gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "3",
      required_tags: ["Merlin_Nose"])
    nose = Hardpoint.find_by!(parent: @model, sc_name: "hardpoint_gun_nose")
    Hardpoint.find_by!(parent: nose, sc_name: "hardpoint_class_2").build.update!(component: merlin_gun)
    port(@model, "hardpoint_gun_tail", types: ["WeaponGun"], min_size: 3, max_size: 3, component: @gun)
    other_merlin_gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "3",
      required_tags: ["Merlin_Nose"])

    assert fleetyards_loadout(fit(["hardpoint_gun_nose/hardpoint_class_2", other_merlin_gun])).save
    assert_refused fleetyards_loadout(fit(["hardpoint_gun_tail", other_merlin_gun])), :component_not_in_slot
  end

  test "names what taking out a refused mount strands, as a save would see it" do
    loadout = fleetyards_loadout(fit(["hardpoint_gun_nose", @other_gimbal], ["hardpoint_gun_nose/hardpoint_gun", @gun]))
    assert loadout.save, loadout.errors.full_messages.to_sentence
    Hardpoint.find_by!(parent: @model, sc_name: "hardpoint_gun_nose").build.update!(types: %w[WeaponGun])

    assert_equal [
      ["hardpoint_gun_nose", :component_not_in_slot],
      ["hardpoint_gun_nose/hardpoint_gun", :slot_unknown]
    ], loadout.reload.item_problems.map { |problem| problem.values_at(:slot_path, :code) }
  end

  test "a save names every reason an item is refused" do
    loadout = fleetyards_loadout(fit(["hardpoint_empty/hardpoint_class_2", @big_gun]))

    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, :parent_not_fitted)
    assert loadout.errors.of_kind?(:items, :slot_unknown)
  end

  test "a mount slot takes mounts, not the guns that go inside them" do
    assert_refused fleetyards_loadout(fit(["hardpoint_gun_nose", @gun])), :component_not_in_slot

    port(@model, "hardpoint_gun_fixed", types: %w[Turret WeaponGun], min_size: 3, max_size: 3, component: @gun)
    assert fleetyards_loadout(fit(["hardpoint_gun_fixed", @gun])).save
  end

  test "a locked slot keeps its part but what sits inside it can change" do
    assert_refused fleetyards_loadout(fit(["hardpoint_gun_wing", @other_gimbal])), :slot_not_editable
    assert fleetyards_loadout(fit(["hardpoint_gun_wing", @gimbal])).save
    assert fleetyards_loadout(fit(["hardpoint_gun_wing/hardpoint_class_2", @small_gun])).save
  end

  test "refuses a slot the ship does not have" do
    assert_refused fleetyards_loadout(fit(["hardpoint_nowhere", @plant])), :slot_unknown
  end

  test "refuses a slot below one that is empty and has no stock part" do
    assert_refused fleetyards_loadout(fit(["hardpoint_empty/hardpoint_gun", @gun])), :parent_not_fitted
  end

  test "refuses a slot the player does not fit, like a door" do
    door = create(:component, component_type: "Door", category: "doors", size: "1")
    port(@model, "hardpoint_door", component: door)

    assert_refused fleetyards_loadout(fit(["hardpoint_door", door])), :slot_unknown
  end

  test "refuses a part the build no longer carries, unless the slot came with it" do
    retired = create(:component, :without_build, component_type: "PowerPlant", category: "powerplant", size: "1")

    assert_refused fleetyards_loadout(fit(["hardpoint_power_plant", retired])), :component_not_in_slot
  end

  test "reads an item id in any case" do
    loadout = fleetyards_loadout([{slot_path: "hardpoint_power_plant", item_type: "Component", item_id: @plant.id.upcase}])

    assert loadout.save, loadout.errors.full_messages.to_sentence
  end

  test "fits only a part whose tags the port and the ship meet" do
    own = create(:component, component_type: "FlightController", category: "controller", size: "1",
      tags: ["RSI_Aurora_mk2_Blade"], required_tags: ["RSI_Aurora_mk2_Blade"])
    sibling = create(:component, component_type: "FlightController", category: "controller", size: "1",
      tags: ["RSI_Aurora_mk2_Blade"], required_tags: ["RSI_Aurora_mk2_Blade"])
    foreign = create(:component, component_type: "FlightController", category: "controller", size: "1",
      tags: ["ANVL_Hornet_F7C_Blade"], required_tags: ["ANVL_Hornet_F7C_Blade"])
    untagged = create(:component, component_type: "FlightController", category: "controller", size: "1",
      tags: ["ANVL_Hornet_F7C_Blade"])
    port(@model, "hardpoint_controller_flight", min_size: 1, max_size: 1, component: own,
      required_tags: ["RSI_Aurora_mk2_Blade"], port_tags: ["RSI_Aurora_mk2_Blade"])

    assert fleetyards_loadout(fit(["hardpoint_controller_flight", sibling])).save
    assert_refused fleetyards_loadout(fit(["hardpoint_controller_flight", foreign])), :component_not_in_slot
    assert_refused fleetyards_loadout(fit(["hardpoint_controller_flight", untagged])), :component_not_in_slot
  end

  test "keeps the port's tags where the stock part has none worth reading" do
    stock = create(:component, component_type: "FlightController", category: "controller", size: "1",
      tags: ["flightReady"])
    foreign = create(:component, component_type: "FlightController", category: "controller", size: "1",
      tags: ["ANVL_Hornet_F7C_Blade"])
    port(@model, "hardpoint_controller_flight", min_size: 1, max_size: 1, component: stock,
      required_tags: ["DRAK_Cutlass_Steel_Blade"])

    assert_refused fleetyards_loadout(fit(["hardpoint_controller_flight", foreign])), :component_not_in_slot
  end

  test "a tag a stock part's own port provides does not carry to the ship's other ports" do
    beam = create(:component, component_type: "WeaponGun", category: "weapons", size: "2",
      tags: ["Taurus_TractorBeam"], required_tags: ["Taurus_TractorBeam"])
    port(@model, "hardpoint_tractor_beam", min_size: 2, max_size: 2, types: %w[WeaponGun], category: "weapons",
      component: beam, port_tags: ["Taurus_TractorBeam"])
    another_beam = create(:component, component_type: "WeaponGun", category: "weapons", size: "2",
      required_tags: ["Taurus_TractorBeam"])

    assert fleetyards_loadout(fit(["hardpoint_tractor_beam", another_beam])).save
    assert_refused fleetyards_loadout(fit(["hardpoint_gun_nose/hardpoint_class_2", another_beam])),
      :component_not_in_slot
  end

  test "a variant's port takes the parts its stock part's tags name" do
    hoplite = create(:component, component_type: "FlightController", category: "controller", size: "1",
      tags: ["AEGS_Vanguard_Hoplite_Blade"])
    another_hoplite = create(:component, component_type: "FlightController", category: "controller", size: "1",
      tags: ["AEGS_Vanguard_Hoplite_Blade"])
    base = create(:component, component_type: "FlightController", category: "controller", size: "1",
      tags: ["AEGS_Vanguard_Blade"])
    port(@model, "hardpoint_controller_flight", min_size: 1, max_size: 1, component: hoplite,
      required_tags: ["AEGS_Vanguard_Blade"])

    assert fleetyards_loadout(fit(["hardpoint_controller_flight", another_hoplite])).save
    assert_refused fleetyards_loadout(fit(["hardpoint_controller_flight", base])), :component_not_in_slot
  end

  test "refuses a part that demands another ship's tag" do
    taurus_beam = create(:component, component_type: "WeaponGun", category: "weapons", size: "2",
      tags: ["Taurus_TractorBeam"], required_tags: ["Taurus_TractorBeam"])

    assert_refused fleetyards_loadout(fit(["hardpoint_gun_nose/hardpoint_class_2", taurus_beam])),
      :component_not_in_slot
  end

  test "takes a part that demands a tag the ship's own parts demand" do
    @gun.update!(required_tags: ["ANVL_Hornet_Base"])
    hornet_gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "3",
      required_tags: ["ANVL_Hornet_Base"])

    assert fleetyards_loadout(fit(["hardpoint_gun_nose/hardpoint_class_2", hornet_gun])).save
  end

  test "a slot only its stock part fits is not offered as a choice" do
    alone = create(:component, component_type: "Radar", category: "radar", size: "1")
    port(@model, "hardpoint_radar", types: ["Radar"], min_size: 1, max_size: 1, component: alone)

    slots = LoadoutSlots.new(@model)

    assert_not slots.swappable?(slots["hardpoint_radar"])
    assert slots.swappable?(slots["hardpoint_gun_nose"])
  end

  test "takes a slot's stock part out, leaving nothing below it" do
    empty = {slot_path: "hardpoint_gun_nose", item_type: "Empty", item_id: nil}
    loadout = fleetyards_loadout([empty])

    assert loadout.save, loadout.errors.full_messages.to_sentence
    assert_equal [["Empty", nil]], loadout.items.pluck(:item_type, :item_id)
    assert_refused fleetyards_loadout([empty] + fit(["hardpoint_gun_nose/hardpoint_class_2", @gun])),
      :parent_not_fitted
    assert_not loadout.slots["hardpoint_gun_nose"].nil?
    assert loadout.slots.emptied?("hardpoint_gun_nose")
  end

  test "a port inside a part that came with a bare gun keeps taking guns" do
    mount = create(:component, component_type: "Turret", category: "weapon_mounts", size: "4")
    port(mount, "hardpoint_weapon", types: %w[Turret WeaponGun], min_size: 2, max_size: 3)
    hull = port(@model, "hardpoint_ball_turret", types: %w[Turret], min_size: 4, max_size: 4, component: mount)
    port(hull, "hardpoint_weapon", min_size: 3, max_size: 3, component: @gun)

    loadout = fleetyards_loadout(fit(["hardpoint_ball_turret/hardpoint_weapon", @small_gun]))

    assert loadout.save, loadout.errors.full_messages.to_sentence
  end

  test "cannot empty a slot that holds nothing" do
    loadout = fleetyards_loadout(fit(["hardpoint_gun_nose", @other_gimbal]) +
      [{slot_path: "hardpoint_gun_nose/hardpoint_gun", item_type: "Empty"}])

    assert_refused loadout, :nothing_to_empty
  end

  test "cannot empty a slot the game locks" do
    assert_refused fleetyards_loadout([{slot_path: "hardpoint_gun_wing", item_type: "Empty"}]), :slot_not_editable
  end

  test "a component removed from the catalogue is unfitted with what sat inside it" do
    loadout = fleetyards_loadout(fit(
      ["hardpoint_power_plant", @plant],
      ["hardpoint_gun_nose", @other_gimbal],
      ["hardpoint_gun_nose/hardpoint_gun", @gun]
    ))
    loadout.save!

    @other_gimbal.destroy!

    assert_equal ["hardpoint_power_plant"], loadout.reload.items.pluck(:slot_path)
  end
end
