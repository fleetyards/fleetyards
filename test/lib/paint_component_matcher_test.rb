# frozen_string_literal: true

require "test_helper"

class PaintComponentMatcherTest < ActiveSupport::TestCase
  setup do
    ModelPaint.delete_all
    Model.delete_all
  end

  private def paint_for(model_name, paint_name)
    model = create(:model, name: model_name)
    create(:model_paint, model:, name: paint_name)
  end

  private def component(name)
    build(:component, category: "paints", name:)
  end

  test "matches a paint the game names after the base ship" do
    paint = paint_for("Terrapin", "IceBreak")

    assert_equal paint, PaintComponentMatcher.new.call(component("Terrapin IceBreak Livery"))
  end

  # The game leaves the variant off, so the ship half has to match as a prefix.
  test "reaches a model whose name carries a variant the game omits" do
    paint = paint_for("Vanguard Hoplite", "Clawed Steel")

    assert_equal paint, PaintComponentMatcher.new.call(component("Vanguard Clawed Steel Livery"))
  end

  # Otherwise a paint the base ship and its variants both carry lands on
  # whichever variant happened to be found first.
  test "prefers the base ship over a variant carrying the same paint" do
    base = paint_for("Terrapin", "IceBreak")
    paint_for("Terrapin Medic", "IceBreak")

    assert_equal base, PaintComponentMatcher.new.call(component("Terrapin IceBreak Livery"))
  end

  test "ignores an aside the store never carries" do
    paint = paint_for("Vulture", "Dying Star")

    assert_equal paint, PaintComponentMatcher.new.call(component("Vulture Dying Star Livery (Modified)"))
  end

  # A paint name identifies nothing on its own -- Fortuna is sold on dozens of
  # ships -- so the ship half is what has to settle it.
  test "does not match a paint of the right name on the wrong ship" do
    paint_for("Vanguard Hoplite", "Fortuna")

    assert_nil PaintComponentMatcher.new.call(component("Ursa Fortuna Livery"))
  end

  test "returns nothing for a paint no model carries" do
    paint_for("Terrapin", "IceBreak")

    assert_nil PaintComponentMatcher.new.call(component("Terrapin Nothing Like It Livery"))
  end

  test "returns nothing for a component with no name" do
    paint_for("Terrapin", "IceBreak")

    assert_nil PaintComponentMatcher.new.call(component(nil))
  end
end
