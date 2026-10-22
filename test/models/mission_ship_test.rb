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

  test "a slot cleared of its foci is not left asking for its old focus" do
    ship = create(:mission_ship, classification: nil, focus: "Light Fighter", foci: %w[light_fighter])

    ship.update!(foci: [])

    assert_nil ship.reload.focus
    assert_not ship.filtered?
  end
end
