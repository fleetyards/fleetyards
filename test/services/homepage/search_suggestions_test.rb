# frozen_string_literal: true

require "test_helper"

module Homepage
  class SearchSuggestionsTest < ActiveSupport::TestCase
    test "suggests one ship, one place and one item" do
      create(:model, name: "Carrack")
      create(:location, name: "Lorville", kind: "city")
      create(:commodity, name: "Quantainium")

      assert_equal ["Carrack", "Lorville", "Quantainium"], SearchSuggestions.new.call
    end

    test "leaves out places and components nobody would search for" do
      create(:location, name: "Nav Point", kind: "nav_point")
      create(:location, name: "PYR1 L2", kind: "station")
      create(:location, name: "Outpost 54", kind: "city")
      create(:component, name: "Carrack Polar Livery", category: "paints")

      assert_empty SearchSuggestions.new.call
    end

    test "suggests a component people look for when there is no commodity" do
      create(:component, name: "Omnisky IX Cannon", category: "weapons")

      assert_equal ["Omnisky IX Cannon"], SearchSuggestions.new.call
    end
  end
end
