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

    test "resolves a ship, a blueprint and a mission by their prefix only" do
      ship = create(:model, name: "Carrack")
      blueprint = create(:blueprint, name: "Omnisky IX Cannon")
      mission = create(:game_mission, name: "Ambush: Outlaw Freighter")

      assert_equal(
        {
          "ship:Carrack" => ["Model", ship.slug],
          "blueprint:Omnisky IX Cannon" => ["Blueprint", blueprint.slug],
          "mission:Ambush: Outlaw Freighter" => ["GameMission", mission.slug]
        },
        resolved("ship:Carrack", "blueprint:Omnisky IX Cannon", "mission:Ambush: Outlaw Freighter")
      )
      assert_empty resolved("Carrack", "Omnisky IX Cannon")
    end

    # A blueprint has the name of what it crafts; a bare name keeps meaning
    # the item it meant before blueprints could be named at all.
    test "keeps a bare name on the item a blueprint shares it with" do
      component = create(:component, name: "Omnisky IX Cannon")
      create(:blueprint, name: "Omnisky IX Cannon")

      assert_equal({"Omnisky IX Cannon" => ["Component", component.slug]}, resolved("Omnisky IX Cannon"))
    end

    test "ignores a hidden ship" do
      create(:model, name: "Secret Ship", hidden: true)

      assert_empty resolved("ship:Secret Ship")
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

    test "search always prefixes a ship, a blueprint or a mission" do
      create(:model, name: "Carrack")
      create(:component, name: "Carrack Engine")

      assert_equal ["ship:Carrack", "Carrack Engine"], @resolver.search("carrack").map(&:token)
    end

    test "resolves a place by its prefix, and only where one place carries the name" do
      lorville = create(:location, name: "Lorville", kind: "city")
      2.times { create(:location, name: "Outpost 54", kind: "outpost") }

      assert_equal({"location:Lorville" => ["Location", lorville.slug]}, resolved("location:Lorville", "location:Outpost 54", "Lorville"))
      assert_equal ["location:Lorville"], @resolver.search("lorv").map(&:token)
    end

    test "search offers a unique name that a much repeated one would crowd out" do
      create_list(:equipment, TokenResolver::SEARCH_LIMIT + 5, name: "Internal Tank")
      create(:equipment, name: "Internal Tank Mk II")

      assert_equal ["Internal Tank Mk II"], @resolver.search("tank").map(&:token)
    end

    test "search keeps a longer name that starts with the query" do
      (1..TokenResolver::SEARCH_LIMIT).each { |n| create(:equipment, name: "A Tank #{n}") }
      create(:equipment, name: "Tank Mk II Heavy")

      assert_equal "Tank Mk II Heavy", @resolver.search("tank").first.token
    end

    test "search ignores a query longer than any name" do
      assert_empty @resolver.search("x" * (TokenResolver::MAX_NAME_LENGTH + 1))
    end

    test "search needs two characters" do
      create(:commodity, name: "Quantainium")

      assert_empty @resolver.search("q")
    end

    test "searches only the catalogues a caller offers" do
      create(:commodity, name: "Carrack Ore")
      create(:model, name: "Carrack")

      assert_equal ["Carrack Ore"], @resolver.search("carrack", within: %w[commodity]).map(&:name)
    end

    test "a prefix outside the offered catalogues finds nothing" do
      create(:model, name: "Carrack")

      assert_empty @resolver.search("ship:carrack", within: %w[commodity])
    end
  end
end
