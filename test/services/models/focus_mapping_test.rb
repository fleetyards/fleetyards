# frozen_string_literal: true

require "test_helper"

module Models
  class FocusMappingTest < ActiveSupport::TestCase
    def map(raw)
      ::Models::FocusMapping.call(raw)
    end

    test "a size tier goes, except on a fighter" do
      assert_equal %w[freight], map("Heavy Freight").foci
      assert_equal %w[mining], map("Light Mining").foci
      assert_equal %w[heavy_fighter], map("Heavy Fighter").foci
    end

    test "recon wording reads as a pathfinder" do
      assert_equal %w[pathfinder], map("Reconnaissance / Intelligence").foci
    end

    test "each part of a combination maps on its own" do
      assert_equal %w[freight starter], map("Starter / Light Freight").foci
      assert_equal %w[medium_fighter freight], map("Light Freight / Medium Fighter").foci
    end

    test "the keys come without their umbrellas" do
      assert_equal %w[destroyer], map("Destroyer").foci
    end

    test "stealth is a flag, not a key" do
      result = map("Stealth Bomber")

      assert_equal %w[bomber], result.foci
      assert result.stealth
      assert_not map("Bomber").stealth
    end

    test "a part it does not know is reported, not guessed" do
      result = map("Turret")

      assert_empty result.foci
      assert_equal %w[turret], result.unknown
    end

    test "the matrix's Multi-Role says nothing a key does" do
      result = map("Multi-Role / Light Carrier")

      assert_equal %w[carrier], result.foci
      assert_empty result.unknown
    end

    test "nothing maps to nothing" do
      assert_empty map(nil).foci
      assert_empty map(" ").foci
    end

    test "every key it gives is one the catalogue knows" do
      assert_empty ::Models::FocusMapping::PARTS.values.flatten.uniq - ::Model::FOCI
    end
  end
end
