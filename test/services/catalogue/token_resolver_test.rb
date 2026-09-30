# frozen_string_literal: true

require "test_helper"

module Catalogue
  class TokenResolverTest < ActiveSupport::TestCase
    setup do
      @resolver = TokenResolver.new
    end

    def resolved(*tokens)
      @resolver.resolve(tokens).to_h { |match| [match.token, [match.type, match.slug]] }
    end

    test "resolves a name to the one listed item that carries it, whatever its case" do
      commodity = create(:commodity, name: "Quantainium")

      assert_equal({"quantainium" => ["Commodity", commodity.slug]}, resolved("quantainium"))
    end

    test "leaves a name several items of one catalogue carry unresolved" do
      create_list(:equipment, 2, name: "Manned Turret")

      assert_empty resolved("Manned Turret")
    end

    test "leaves a name two catalogues carry unresolved, until a prefix picks one" do
      create(:component, name: "Mercury")
      commodity = create(:commodity, name: "Mercury")

      assert_empty resolved("Mercury")
      assert_equal({"commodity:Mercury" => ["Commodity", commodity.slug]}, resolved("commodity:Mercury"))
    end

    test "reads an unknown prefix as part of the name" do
      commodity = create(:commodity, name: "Mk2: Deluxe")

      assert_equal({"Mk2: Deluxe" => ["Commodity", commodity.slug]}, resolved("Mk2: Deluxe"))
    end

    test "ignores what the catalogue no longer lists" do
      create(:commodity, :without_build, name: "Retired Ore")

      assert_empty resolved("Retired Ore")
    end

    test "ignores unknown names and blank tokens" do
      assert_empty resolved("Nothing By This Name", "", "component:")
    end

    test "search offers names that resolve, with the token to insert" do
      create(:commodity, name: "Quantainium")
      create(:commodity, name: "Raw Quantainium")
      create_list(:equipment, 2, name: "Quantainium Scanner")

      tokens = @resolver.search("quant").map(&:token)

      assert_equal ["Quantainium", "Raw Quantainium"], tokens
    end

    test "search prefixes a name another catalogue carries too" do
      create(:component, name: "Mercury")
      create(:commodity, name: "Mercury")

      assert_equal ["commodity:Mercury", "component:Mercury"], @resolver.search("merc").map(&:token).sort
    end

    test "search needs two characters" do
      create(:commodity, name: "Quantainium")

      assert_empty @resolver.search("q")
    end
  end
end
