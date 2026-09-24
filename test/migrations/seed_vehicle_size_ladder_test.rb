# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260920120000_seed_vehicle_size_ladder.rb")

class SeedVehicleSizeLadderTest < ActiveSupport::TestCase
  # `update_slugs` runs before every save and derives the slug from the name and
  # the manufacturer, so a slug handed to the factory does not survive.
  def with_slug(model, slug)
    Model.where(id: model.id).update_all(slug: slug)
    model
  end

  def vehicle(slug, **attributes)
    with_slug(create(:model, size: "vehicle", ground: true, **attributes), slug)
  end

  def seed
    SeedVehicleSizeLadder.new.up
  end

  test "a vehicle is placed on the rung the curation gives it" do
    atls = vehicle("argo-atls")
    ursa = vehicle("rsi-ursa")
    nova = vehicle("tmbl-nova")

    seed

    assert_equal "extra_extra_small", atls.reload.vehicle_size
    assert_equal "large", ursa.reload.vehicle_size
    assert_equal "extra_extra_large", nova.reload.vehicle_size
  end

  # Volume puts the Cyclone above the Ursa, because its recorded beam is wider
  # than one. The ladder says otherwise, and the ladder is the curation.
  test "the Cyclone sits a class below the Ursa despite measuring larger" do
    cyclone = vehicle("tmbl-cyclone", length: 6.0, beam: 8.75, height: 3.5)
    ursa = vehicle("rsi-ursa", length: 7.6, beam: 5.5, height: 2.2)

    seed

    assert_equal "medium", cyclone.reload.vehicle_size
    assert_equal "large", ursa.reload.vehicle_size
  end

  test "a class placed by hand is left where it is" do
    placed = vehicle("tmbl-nova", vehicle_size: "large")

    seed

    assert_equal "large", placed.reload.vehicle_size
  end

  # The validation refuses a ladder value on anything but a vehicle, so a model
  # whose `size` is not yet "vehicle" must come out of this unplaced rather
  # than invalid.
  test "a model that is not a vehicle is skipped" do
    ship = with_slug(create(:model, size: "small"), "rsi-ursa")

    seed

    assert_nil ship.reload.vehicle_size
  end

  test "it does not roll back" do
    assert_raises(ActiveRecord::IrreversibleMigration) { SeedVehicleSizeLadder.new.down }
  end

  test "every slug on the ladder is placed exactly once" do
    slugs = SeedVehicleSizeLadder::LADDER.values.flatten

    assert_equal slugs.uniq, slugs
    assert_equal 44, slugs.size
  end
end
