# frozen_string_literal: true

require "test_helper"

class VehicleLoadoutCraftingTest < ActiveSupport::TestCase
  setup do
    @model = create(:model, production_status: "flight-ready")
    @vehicle = create(:vehicle, model: @model)

    @shield = create(:component, component_type: "Shield", category: "shieldgenerator", size: "1")
    @other_shield = create(:component, component_type: "Shield", category: "shieldgenerator", size: "1")
    create(:hardpoint, parent: @model, sc_name: "hardpoint_shield", source: :game_files,
      types: ["Shield"], min_size: 1, max_size: 1, component: @shield)

    cooler = create(:component, component_type: "Cooler", category: "cooler", size: "1")
    @other_cooler = create(:component, component_type: "Cooler", category: "cooler", size: "1")
    create(:hardpoint, parent: @model, sc_name: "hardpoint_cooler", source: :game_files,
      types: ["Cooler"], min_size: 1, max_size: 1, component: cooler)

    @blueprint = create(:blueprint, craftable: @shield)
    [0, 1].each { |position| create(:blueprint_cost_slot, build: @blueprint.build, position:) }
  end

  def crafted_item(component: @shield, blueprint: @blueprint, qualities: [{position: 0, quality: 900}])
    {
      slot_path: "hardpoint_shield",
      item_type: "Component",
      item_id: component.id,
      crafted: {blueprint_id: blueprint.id, qualities:}
    }
  end

  def fleetyards_loadout(items)
    VehicleLoadout.new(vehicle: @vehicle, kind: "fleetyards", item_list: items)
  end

  def assert_refused(loadout, kind)
    assert_not loadout.save
    assert loadout.errors.of_kind?(:items, kind), loadout.errors.details.inspect
  end

  test "saves a crafted part with its recipe and a quality per slot" do
    loadout = fleetyards_loadout([crafted_item(qualities: [{position: 0, quality: 900}, {position: 1, quality: 0}])])

    assert loadout.save, loadout.errors.full_messages.to_sentence

    item = loadout.items.sole
    assert item.crafted?
    assert_equal @blueprint.id, item.blueprint_id
    assert_equal({"0" => 900, "1" => 0}, item.crafted_qualities)
  end

  test "crafts the stock part, which is then saved as an item of its own" do
    loadout = fleetyards_loadout([crafted_item])

    assert loadout.save, loadout.errors.full_messages.to_sentence
    assert_equal [@shield.id], loadout.items.pluck(:item_id)
  end

  test "a part without crafting keeps no recipe" do
    loadout = fleetyards_loadout([{slot_path: "hardpoint_shield", item_type: "Component", item_id: @other_shield.id}])

    assert loadout.save, loadout.errors.full_messages.to_sentence
    assert_not loadout.items.sole.crafted?
    assert_equal({}, loadout.items.sole.crafted_qualities)
  end

  test "refuses a recipe that makes another part" do
    assert_refused fleetyards_loadout([crafted_item(component: @other_shield)]), :crafted_not_craftable
  end

  test "refuses a recipe the build in force no longer describes" do
    retired = create(:blueprint, :without_build, craftable: @shield)

    assert_refused fleetyards_loadout([crafted_item(blueprint: retired)]), :crafted_not_craftable
  end

  test "refuses a slot the recipe does not have" do
    assert_refused fleetyards_loadout([crafted_item(qualities: [{position: 2, quality: 500}])]), :crafted_slot_unknown
  end

  test "refuses a quality off the game's scale" do
    assert_refused fleetyards_loadout([crafted_item(qualities: [{position: 0, quality: 1001}])]),
      :crafted_quality_out_of_range
    assert_refused fleetyards_loadout([crafted_item(qualities: [{position: 0, quality: -1}])]),
      :crafted_quality_out_of_range
  end

  test "refuses a recipe slot named twice" do
    assert_refused fleetyards_loadout([crafted_item(qualities: [{position: 0, quality: 900}, {position: 0, quality: 100}])]),
      :crafted_slot_repeated
  end

  test "keeps a saved crafting whose recipe a new build dropped, while the rest of the loadout changes" do
    loadout = fleetyards_loadout([crafted_item])
    assert loadout.save, loadout.errors.full_messages.to_sentence

    @blueprint.builds.destroy_all

    loadout = VehicleLoadout.find(loadout.id)
    loadout.item_list = [
      crafted_item,
      {slot_path: "hardpoint_cooler", item_type: "Component", item_id: @other_cooler.id}
    ]
    assert loadout.save, loadout.errors.full_messages.to_sentence
    assert loadout.items.find_by(slot_path: "hardpoint_shield").crafted?

    loadout.item_list = [crafted_item(qualities: [{position: 0, quality: 100}])]
    assert_refused loadout, :crafted_not_craftable
  end

  test "refuses crafting on an emptied slot" do
    item = crafted_item.merge(item_type: "Empty")

    assert_refused fleetyards_loadout([item]), :crafted_not_component
  end
end
