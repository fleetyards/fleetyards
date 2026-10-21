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

    test "opens on the catalogue with the strongest match" do
      create(:commodity, name: "Support Crate")
      create(:location, name: "Port Tressler")

      assert_equal ["Location", "Commodity"], search("port").map(&:first)
    end

    test "offers at most five per catalogue" do
      7.times { |n| create(:commodity, name: "Ore #{n}") }

      assert_equal Search::PER_TYPE, search("ore").size
    end

    test "carries the picture an item has, and a blueprint the one of what it crafts" do
      component = create(:component, :with_store_image, name: "Omni Cannon")
      create(:blueprint, name: "Omni Cannon", craftable: component)
      create(:commodity, name: "Omni Ore")

      images = Search.new.call("omni").flat_map(&:items).to_h { |result| [result.type, result.image&.blob&.filename&.to_s] }

      assert_equal({"Component" => "test.png", "Blueprint" => "test.png", "Commodity" => nil}, images)
    end

    test "shows a ship by its angled render rather than its store image" do
      png = Rails.root.join("test/fixtures/files/test.png")
      ship = create(:model, name: "Omni Hauler")
      ship.store_image.attach(io: File.open(png), filename: "store.png")
      ship.angled_view.attach(io: File.open(png), filename: "angled.png")

      assert_equal "angled.png", Search.new.call("omni").first.items.first.image.filename.to_s
    end

    test "ignores a query too short to mean anything, and what the catalogue hides" do
      create(:model, name: "Secret Ship", hidden: true)

      assert_empty search("s")
      assert_empty search("secret")
    end
  end
end
