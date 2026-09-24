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
  # berth at all -- a fresh way to grow the orphans `RemoveOrphanedDocks` had
  # to delete.
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

# Two answers, and the curated one wins where it exists: a berth that says what
# it is built for has answered, and what could be crammed in is not shown.
class DockFitsByClassTest < ActiveSupport::TestCase
  def hangar(ship_size: :small, **attributes)
    create(:dock, :with_dimensions, dock_type: :hangar, ship_size:, **attributes)
  end

  def ship(length:, beam:, height:, **attributes)
    create(:model, length:, beam:, height:, size: "small", **attributes)
  end

  test "a described berth takes its class and everything below" do
    dock = hangar
    create(:dock_capacity, dock:, ladder: :ship, size: "small", quantity: 3)

    assert dock.reload.fits?(ship(length: 40.0, beam: 40.0, height: 15.0))
    assert dock.fits?(ship(length: 12.0, beam: 10.0, height: 5.0))
  end

  # The Idris: a 100m hall that is three Gladius pads. A medium ship goes in it
  # if you are careful, and the catalogue declines to say so.
  test "a described berth refuses a class above it, whatever the hall measures" do
    dock = create(:dock, dock_type: :hangar, ship_size: :small, length: 100, beam: 25, height: 8)
    create(:dock_capacity, dock:, ladder: :ship, size: "small", quantity: 3)

    medium = ship(length: 55.0, beam: 30.0, height: 17.0)

    assert_equal "medium", ::Dock.ship_size_for(medium.length, medium.beam, medium.height)
    assert_not dock.reload.fits?(medium)
  end

  # The other half of `class ∪ additions`: the hull somebody checked in game.
  test "a named ship fits whatever its class says" do
    dock = hangar
    create(:dock_capacity, dock:, ladder: :ship, size: "extra_small", quantity: 1)
    oversized = ship(length: 120.0, beam: 60.0, height: 30.0)

    assert_not dock.reload.fits?(oversized)

    create(:dock_addition, dock:, model: oversized)

    assert dock.reload.fits?(oversized)
  end

  # The Merchantman: one landing pad, no dimensions, silent until now.
  test "a described berth answers without being measured" do
    dock = create(:dock, dock_type: :landingpad, ship_size: :small, length: nil, beam: nil, height: nil)
    create(:dock_capacity, dock:, ladder: :ship, size: "small", quantity: 1)

    assert_not dock.measured?
    assert dock.reload.fits?(ship(length: 40.0, beam: 40.0, height: 15.0))
  end

  test "an undescribed berth still answers by its envelope" do
    dock = hangar

    assert_not dock.described?
    assert dock.fits?(ship(length: 4.0, beam: 2.0, height: 2.0))
  end

  # A berth nobody has described has not said that the ship it names is the only
  # one it takes -- the name is added to the envelope rather than replacing it.
  test "a named ship does not narrow an undescribed berth" do
    dock = hangar
    named = ship(length: 120.0, beam: 60.0, height: 30.0)
    create(:dock_addition, dock:, model: named)

    assert dock.reload.fits?(named)
    assert dock.fits?(ship(length: 4.0, beam: 2.0, height: 2.0))
  end

  # Zeroes fit everywhere, so an unmeasured hull is never compared against an
  # envelope -- but it can still be named.
  test "an unmeasured hull is named rather than compared" do
    dock = hangar
    unmeasured = create(:model, length: 0, beam: 0, height: 0, size: "small")

    assert_not dock.fits?(unmeasured)

    create(:dock_addition, dock:, model: unmeasured)

    assert dock.reload.fits?(unmeasured)
  end

  # A docking port is a connection, not a place a hull is set down -- and the
  # admin endpoint will happily hang entries off one.
  test "a docking port refuses what is recorded on it" do
    dock = create(:dock, :with_dimensions, dock_type: :dockingport)
    create(:dock_capacity, dock:, ladder: :ship, size: "capital", quantity: 1)
    model = ship(length: 20.0, beam: 10.0, height: 5.0)
    create(:dock_addition, dock:, model:)

    assert_not dock.reload.fits?(model)
  end

  # A hull larger than every pad box comes back `capital`, which is the rung a
  # capital berth is described at -- so it fits, and the scope has to agree.
  test "a capital berth takes a hull larger than every box" do
    dock = create(:dock, dock_type: :hangar, ship_size: :capital, length: 300, beam: 200, height: 80)
    create(:dock_capacity, dock:, ladder: :ship, size: "capital", quantity: 1)

    enormous = ship(length: 250.0, beam: 180.0, height: 70.0)

    assert_equal "capital", ::Dock.ship_size_for(enormous.length, enormous.beam, enormous.height)
    assert dock.reload.fits?(enormous)
  end

  test "a garage described as Ursa-class takes an Ursa and refuses a Nova" do
    dock = create(:dock, :with_dimensions, dock_type: :garage)
    create(:dock_capacity, dock:, ladder: :vehicle, size: "large", quantity: 1)

    ursa = create(:model, size: "vehicle", vehicle_size: "large", length: 7.6, beam: 5.5, height: 2.2)
    nova = create(:model, size: "vehicle", vehicle_size: "extra_extra_large", length: 16.0, beam: 7.0, height: 5.0)

    assert dock.reload.fits?(ursa)
    assert_not dock.fits?(nova)
  end

  # The ship/vehicle gate is what keeps a snub off a cargo grid today. A class
  # says what a berth takes, so the gate stops being the thing that decides.
  test "a berth described on both ladders takes both" do
    dock = create(:dock, :with_dimensions, dock_type: :cargogrid)
    create(:dock_capacity, dock:, ladder: :vehicle, size: "medium", quantity: 6)
    create(:dock_capacity, dock:, ladder: :ship, size: "extra_extra_small", quantity: 1)

    snub = ship(length: 10.0, beam: 8.0, height: 4.0)
    cyclone = create(:model, size: "vehicle", vehicle_size: "medium", length: 6.0, beam: 4.0, height: 2.5)

    assert dock.reload.fits?(snub)
    assert dock.fits?(cyclone)
  end
end
