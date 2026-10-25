# frozen_string_literal: true

require "test_helper"

# The cases `craftedComponent.fixtures.spec.ts` reads: a recipe's slots, the
# grades chosen and a part's figures, with what the browser crafts them into.
# The server has to land on the same figures.
class CraftedFiguresTest < ActiveSupport::TestCase
  Slot = Struct.new(:position, :modifiers)
  Modifier = Struct.new(:property_key, :name, :ramp, :start_quality, :end_quality, :modifier_at_start, :modifier_at_end)

  CASES = JSON.parse(Rails.root.join("test/fixtures/crafted_figures/cases.json").read).map do |fixture|
    fixture.deep_transform_keys(&:underscore)
  end

  test "there are cases to check" do
    assert_not_empty CASES
  end

  CASES.each do |fixture|
    test "agrees with the browser on #{fixture["case"]}" do
      slots = fixture["slots"].map do |slot|
        Slot.new(slot["position"], slot["modifiers"].map { |modifier| Modifier.new(**modifier.symbolize_keys.slice(*Modifier.members)) })
      end

      crafted = CraftedFigures.new(slots, fixture["qualities"]).type_data(fixture["type_data"])

      assert_figures fixture.fetch("expected"), crafted
    end
  end

  private def assert_figures(expected, actual, path = [])
    assert_equal expected.keys.sort, actual.keys.sort, "keys at #{path.join(".")}"

    expected.each do |key, value|
      if value.is_a?(Hash)
        assert_figures(value, actual[key], path + [key])
      else
        assert_in_delta value, actual[key], 1e-9, "at #{(path + [key]).join(".")}"
      end
    end
  end
end
