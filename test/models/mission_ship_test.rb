# frozen_string_literal: true

require "test_helper"

class MissionShipTest < ActiveSupport::TestCase
  test "a slot asking for a light fighter does not widen to every fighter" do
    assert_equal %w[light_fighter], create(:mission_ship, foci: %w[light_fighter]).foci
  end

  test "a slot may only ask for a focus the catalogue knows" do
    ship = build(:mission_ship, foci: %w[turret])

    assert_not ship.valid?
    assert_includes ship.errors.attribute_names, :foci
  end
end
