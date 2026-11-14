# frozen_string_literal: true

require "test_helper"

module Catalogue
  class SearchTest < ActiveSupport::TestCase
    def search(query)
      Search.new.call(query).flat_map(&:items).map { |result| [result.type, result.name, result.detail] }
    end

    test "answers from every catalogue, ships first" do
      create(:commodity, name: "Omni Ore")
      create(:model, name: "Omni Hauler", manufacturer: create(:manufacturer, name: "Anvil"))
      create(:game_mission, name: "Omni Delivery", org_name: "Covalex")

      assert_equal(
        [
          ["Model", "Omni Hauler", "Anvil"],
          ["Commodity", "Omni Ore", nil],
          ["GameMission", "Omni Delivery", "Covalex"]
        ],
        search("omni")
      )
    end

    test "keeps a name several items carry, told apart by size and maker" do
      maker = create(:manufacturer, name: "Behring")
      create(:component, name: "GVSR Repeater", size: "2", manufacturer: maker)
      create(:component, name: "GVSR Repeater", size: "3", manufacturer: maker)

      assert_equal(
        [["Component", "GVSR Repeater", "S2 · Behring"], ["Component", "GVSR Repeater", "S3 · Behring"]],
        search("gvsr").sort
      )
    end

    test "collapses items nobody could tell apart" do
      create_list(:component, 3, name: "GVSR Repeater", size: "10")

      assert_equal [["Component", "GVSR Repeater", "S10"]], search("gvsr")
    end

    test "names a place by the place it sits in" do
      planet = create(:location, name: "microTech")
      create(:location, name: "Port Tressler", parent: planet)

      assert_includes search("tressler"), ["Location", "Port Tressler", "microTech"]
    end

    test "draws a body in its colour and a system as its star" do
      system = create(:location, name: "Omni System", kind: "system")
      create(:location, name: "Omni Star", kind: "star", system:, color: "#ffb066")
      create(:location, name: "Omni III", kind: "planet", system:, color: "#8fb8d0", body_type: "ice_giant")
      create(:location, name: "Omni Station", kind: "station", system:)

      appearances = Search.new.call("omni").flat_map(&:items).to_h { |result| [result.name, result.appearance&.to_h&.slice(:kind, :color, :body_type)] }

      assert_equal({kind: "system", color: "#ffb066", body_type: nil}, appearances["Omni System"])
      assert_equal({kind: "planet", color: "#8fb8d0", body_type: "ice_giant"}, appearances["Omni III"])
      assert_equal "station", appearances["Omni Station"][:kind]
    end

    test "ranks a name that starts with the query, then a word that does, then the rest" do
      create(:commodity, name: "Support Crate")
      create(:commodity, name: "Old Port Crate")
      create(:commodity, name: "Port Crate")

      assert_equal ["Port Crate", "Old Port Crate", "Support Crate"], search("port").map(&:second)
    end

    test "finds a name however the reader spaced it" do
      create(:model, name: "North Star")
      create(:component, name: "F7C-M Super Hornet Mount")

      assert_equal ["North Star"], search("northstar").map(&:second)
      assert_equal ["North Star"], search("north-star").map(&:second)
      assert_equal ["F7C-M Super Hornet Mount"], search("f7cm").map(&:second)
      assert_empty search("--")
    end

    test "finds a name a letter or two off once nothing matches as typed" do
      create(:model, name: "North Star")
      create(:model, name: "Carrack")
      create(:commodity, name: "Northern Lights")

      assert_equal [["Model", "North Star"]], search("nortstar").map { |row| row.first(2) }
      assert_equal ["Carrack"], search("carack").map(&:second)
      assert_not Search.new.call("nortstar").first.has_more
    end

    test "takes a question mark in a near miss as text" do
      create(:model, name: "Carrack")

      assert_equal ["Carrack"], search("carack?").map(&:second)
      assert_empty search("como quitar el hecho de estar a la venta?")
    end

    test "offers no near miss while something matches as typed" do
      create(:model, name: "Starfarer")
      create(:commodity, name: "Stor-All Crate")

      assert_equal ["Starfarer"], search("starf").map(&:second)
    end

    test "leaves a short query to match as typed" do
      create(:commodity, name: "Ore")

      assert_empty search("orx")
    end

    test "opens on the catalogue with the strongest match" do
      create(:commodity, name: "Support Crate")
      create(:location, name: "Port Tressler")

      assert_equal ["Location", "Commodity"], search("port").map(&:first)
    end

    test "offers at most five per catalogue" do
      7.times { |n| create(:commodity, name: "Ore #{n}") }

      assert_equal Search::PER_TYPE, search("ore").size
    end

    test "finds a faction and the missions it offers by its name" do
      faction = create(:faction, name: "InterSec Defense Solutions")
      faction.build.update!(focus: "Security")
      create(:game_mission, name: "Clear the Outpost", org_name: "InterSec Defense Solutions")
      create(:game_mission, name: "Clear the Outpost", org_name: "Foxwell Enforcement")

      assert_equal(
        [
          ["Faction", "InterSec Defense Solutions", "Security"],
          ["GameMission", "Clear the Outpost", "InterSec Defense Solutions"]
        ],
        search("intersec")
      )
    end

    test "ranks a mission named for the query above one only its org matches" do
      create(:game_mission, name: "Zzz Patrol", org_name: "InterSec Defense Solutions")
      create(:game_mission, name: "InterSec Patrol", org_name: "Foxwell Enforcement")

      assert_equal ["InterSec Patrol", "Zzz Patrol"], search("intersec").map(&:second)
    end

    test "ranks a name holding the query mid-word above a short one only its org matches" do
      create(:game_mission, name: "Ab", org_name: "Red Wind Linehaul")
      create(:game_mission, name: "A Hundred Crates To Move", org_name: "Foxwell Enforcement")

      assert_equal ["A Hundred Crates To Move", "Ab"], search("red").map(&:second)
    end

    test "says there is more where variants of a mission collapsed into one row" do
      2.times { create(:game_mission, name: "Clear the Outpost", org_name: "InterSec Defense Solutions") }

      group = Search.new.call("intersec").sole

      assert_equal 1, group.items.size
      assert group.has_more
    end

    test "leaves out a faction the current build does not carry" do
      create(:faction, name: "InterSec Gone", version: nil, with_build: false)

      assert_empty search("intersec")
    end

    test "says when a catalogue has more than it offers" do
      5.times { |n| create(:commodity, name: "Ore #{n}") }
      assert_equal [false], Search.new.call("ore").map(&:has_more)

      create(:commodity, name: "Ore 5")
      assert_equal [true], Search.new.call("ore").map(&:has_more)
    end

    test "carries the picture an item has, and a blueprint none without an angled render to draw" do
      component = create(:component, :with_store_image, name: "Omni Cannon")
      create(:blueprint, name: "Omni Cannon", craftable: component)
      create(:commodity, name: "Omni Ore")

      images = Search.new.call("omni").flat_map(&:items).to_h { |result| [result.type, result.image&.blob&.filename&.to_s] }

      assert_equal({"Component" => "test.png", "Blueprint" => nil, "Commodity" => nil}, images)
    end

    test "shows a ship by its angled render rather than its store image" do
      png = Rails.root.join("test/fixtures/files/test.png")
      ship = create(:model, name: "Omni Hauler")
      ship.store_image.attach(io: File.open(png), filename: "store.png")
      ship.angled_view.attach(io: File.open(png), filename: "angled.png")

      assert_equal "angled.png", Search.new.call("omni").first.items.first.image.filename.to_s
    end

    test "shows a component, equipment and a blueprint by the angled render where there is one" do
      png = Rails.root.join("test/fixtures/files/test.png")
      component = create(:component, :with_store_image, name: "Omni Cannon")
      component.angled_view.attach(io: File.open(png), filename: "angled.png")
      create(:blueprint, name: "Omni Cannon", craftable: component)
      equipment = create(:equipment, name: "Omni Helmet")
      equipment.angled_view.attach(io: File.open(png), filename: "angled.png")

      images = Search.new.call("omni").flat_map(&:items).to_h { |result| [result.type, result.image&.blob&.filename&.to_s] }

      assert_equal({"Component" => "angled.png", "Equipment" => "angled.png", "Blueprint" => "angled.png"}, images)
    end

    test "pictures no blueprint whose item has no angled render to draw" do
      create(:blueprint, name: "Omni Ore", craftable: create(:commodity, :with_store_image, name: "Omni Ore"))

      blueprint = Search.new.call("omni").find { |group| group.type == "Blueprint" }.items.first

      assert_nil blueprint.image
    end

    test "ignores a query too short to mean anything, and what the catalogue hides" do
      create(:model, name: "Secret Ship", hidden: true)

      assert_empty search("s")
      assert_empty search("secret")
    end
  end
end
