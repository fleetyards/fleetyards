# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: docks
#
#  id            :uuid             not null, primary key
#  access        :integer
#  beam          :decimal(15, 2)
#  dock_type     :integer
#  group         :string
#  height        :decimal(15, 2)
#  length        :decimal(15, 2)
#  max_ship_size :integer
#  min_ship_size :integer
#  name          :string
#  parent_type   :string           not null
#  ship_size     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_id     :uuid             not null
#
# Indexes
#
#  index_docks_on_parent_type_and_parent_id  (parent_type,parent_id)
#
class DockTest < ActiveSupport::TestCase
  test "a dock belongs to a ship" do
    model = create(:model)

    assert create(:dock, parent: model).valid?
    assert_equal 1, model.docks.count
  end

  # The reason the parent is polymorphic at all: the Galaxy's medic module
  # carries a vehicle lift, and a module is not a ship.
  test "a dock belongs to a module" do
    model_module = create(:model_module)

    assert create(:dock, parent: model_module).valid?
    assert_equal 1, model_module.docks.count
  end

  # `parent_type` is a plain string column, so without the guard the admin API
  # would take any class name and a dock could hang off something that is not a
  # berth at all -- a fresh way to grow the orphans #4864 had to delete.
  test "a dock belongs to nothing else" do
    manufacturer = create(:manufacturer)

    dock = build(:dock, parent: manufacturer)

    assert_not dock.valid?
    assert_includes dock.errors[:parent_type], "is not included in the list"
  end

  test "a dock belongs to something" do
    dock = build(:dock, parent: nil)

    assert_not dock.valid?
  end

  # Making the association optional removed the check that the row exists along
  # with the constantizing. A known type plus any UUID would have saved a dock
  # hanging off nothing.
  test "a dock refuses a parent that does not exist" do
    dock = build(:dock, parent_type: "Model", parent_id: SecureRandom.uuid)

    assert_not dock.valid?
    assert_includes dock.errors[:parent], "can't be blank"
  end

  # `belongs_to`'s own presence check would constantize `parent_type` and raise
  # NameError out of validation, which is a 500 where an invalid record belongs.
  test "a dock refuses a class that does not exist, without raising" do
    dock = build(:dock, parent_type: "NoSuchClass", parent_id: SecureRandom.uuid)

    assert_not dock.valid?
    assert_includes dock.errors[:parent_type], "is not included in the list"
  end

  # The create form no longer preselects a type, so nothing else may either: a
  # berth saved without one would be a landing pad or a garage by accident.
  test "a dock needs a type and a size" do
    assert_not build(:dock, dock_type: nil).valid?
    assert_not build(:dock, ship_size: nil).valid?
  end

  # A cargo grid costs cargo capacity and a garage does not, but both take a
  # vehicle -- so the new type has to be classified with the vehicle berths or
  # it would silently be offered to ships.
  test "a cargo grid is a vehicle berth" do
    dock = build(:dock, dock_type: :cargogrid)

    assert dock.for_vehicles?
    assert_not dock.for_ships?
    assert dock.berth?
  end

  test "a cargo grid takes a vehicle and refuses a ship" do
    dock = create(:dock, :with_dimensions, dock_type: :cargogrid)
    vehicle = create(:model, length: 8.0, beam: 5.0, height: 3.0, size: "vehicle")
    ship = create(:model, length: 8.0, beam: 5.0, height: 3.0, size: "small")

    assert dock.fits?(vehicle)
    assert_not dock.fits?(ship)
  end

  # Destroying the carrier takes its berths, whichever side they hang off.
  # Not part of the fit check on purpose: a tractor beam will get a car into a
  # hangar, badly, and "possible but awkward" is not a comparison of metres.
  test "how a berth is reached is a label, not a condition" do
    dock = create(:dock, :with_dimensions, dock_type: :garage, access: :tractor_beam)
    vehicle = create(:model, length: 4.0, beam: 2.0, height: 2.0, size: "vehicle")

    assert_equal "Tractor Beam", dock.access_label
    assert dock.fits?(vehicle)
  end

  test "a berth nobody has looked at has no access label" do
    assert_nil create(:dock, access: nil).access_label
  end

  test "a module takes its docks with it" do
    model_module = create(:model_module)
    create(:dock, parent: model_module)

    assert_difference("Dock.count", -1) { model_module.destroy }
  end
end

# The pad class a hull lands on. SHIP_SIZE_METRICS is the game's own
# `landingpadsize` table, so these are the game's boxes rather than ours.
class DockShipSizeForTest < ActiveSupport::TestCase
  test "a hull takes the smallest pad that contains it" do
    assert_equal "extra_extra_small", Dock.ship_size_for(7.0, 5.4, 3.0)
    assert_equal "extra_small", Dock.ship_size_for(30.0, 20.0, 10.0)
    assert_equal "small", Dock.ship_size_for(47.0, 40.0, 15.0)
    assert_equal "medium", Dock.ship_size_for(80.0, 50.0, 17.0)
    assert_equal "large", Dock.ship_size_for(120.0, 70.0, 30.0)
    assert_equal "extra_large", Dock.ship_size_for(250.0, 150.0, 60.0)
  end

  # A pad does not care which way round a ship sits on it, so the footprint is
  # compared as a pair rather than axis by axis.
  test "the footprint is compared either way round" do
    assert_equal Dock.ship_size_for(48.0, 30.0, 15.0), Dock.ship_size_for(30.0, 48.0, 15.0)
  end

  # Height is the axis that most often decides it: the Mercury is 19m tall
  # against a small pad's 16.
  test "height alone can push a hull up a class" do
    assert_equal "small", Dock.ship_size_for(40.0, 40.0, 16.0)
    assert_equal "medium", Dock.ship_size_for(40.0, 40.0, 17.0)
  end

  test "a hull larger than every pad is capital" do
    assert_equal "capital", Dock.ship_size_for(300.0, 200.0, 70.0)
  end

  test "an unmeasured hull has no class" do
    assert_nil Dock.ship_size_for(0, 0, 0)
    assert_nil Dock.ship_size_for(20.0, 10.0, 0)
  end
end
