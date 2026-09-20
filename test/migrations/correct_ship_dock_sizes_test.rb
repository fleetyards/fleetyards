# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260920130000_correct_ship_dock_sizes.rb")

class CorrectShipDockSizesTest < ActiveSupport::TestCase
  # `update_slugs` derives the slug on every save, so one handed to the factory
  # does not survive.
  def ship(slug)
    model = create(:model)
    Model.where(id: model.id).update_all(slug: slug)
    model
  end

  def hangar(model, ship_size)
    create(:dock, parent: model, name: "Hangar", dock_type: :hangar, ship_size: ship_size)
  end

  def correct
    CorrectShipDockSizes.new.up
  end

  test "the Polaris stops being the smallest class on the second largest hangar" do
    polaris = hangar(ship("rsi-polaris"), :extra_small)

    correct

    assert_equal "small", polaris.reload.ship_size
  end

  test "the Galaxy moves up one and the Odyssey joins the Polaris" do
    galaxy = hangar(ship("rsi-galaxy"), :extra_extra_small)
    odyssey = hangar(ship("misc-odyssey"), :extra_small)

    correct

    assert_equal "extra_small", galaxy.reload.ship_size
    assert_equal "small", odyssey.reload.ship_size
  end

  test "a size somebody has already corrected is left where it is" do
    polaris = hangar(ship("rsi-polaris"), :medium)

    correct

    assert_equal "medium", polaris.reload.ship_size
  end

  # The Merchantman's only berth is a `landingpad` called "Hangar", so the name
  # alone does not identify the berth these figures are about.
  test "a dock of another type wearing the same name is untouched" do
    polaris = ship("rsi-polaris")
    pad = create(:dock, parent: polaris, name: "Hangar", dock_type: :landingpad, ship_size: :extra_small)

    correct

    assert_equal "extra_small", pad.reload.ship_size
  end

  test "it does not roll back" do
    hangar(ship("rsi-polaris"), :extra_small)

    assert_raises(ActiveRecord::IrreversibleMigration) { CorrectShipDockSizes.new.down }
  end

  test "another dock on the same ship is untouched" do
    polaris = ship("rsi-polaris")
    hangar(polaris, :extra_small)
    garage = create(:dock, parent: polaris, name: "Garage / Cargo", dock_type: :garage, ship_size: :extra_extra_small)

    correct

    assert_equal "extra_extra_small", garage.reload.ship_size
  end
end
