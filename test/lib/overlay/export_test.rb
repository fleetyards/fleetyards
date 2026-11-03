# frozen_string_literal: true

require "test_helper"

module Overlay
  class ExportTest < ActiveSupport::TestCase
    setup do
      @weapon = create(:component, :weapon, :with_manufacturer,
        name: "10-Series Greatsword Cannon",
        sc_key: "kbar_ballisticcannon_s2",
        grade: "A",
        type_data: {"fire_rate" => 250, "speed" => 1196, "range" => 2703, "damage_per_shot" => {"physical" => 72.99}},
        durability: {"health" => 850, "mass" => 192, "resistances" => {"physical" => 0.6}})
      @armor = create(:equipment, :armor, name: "Interceptor Helmet")
      @ship = create(:model, :in_game, name: "Avenger Titan", hull_health: 9000, scm_speed: 220, max_speed: 1240)
    end

    def build(channel = "live")
      Export.new(channel).build
    end

    def items(result = build)
      JSON.parse(ActiveSupport::Gzip.decompress(result.items_gzip)).fetch("items")
    end

    def item(kind, slug, result = build)
      items(result).find { |entry| entry["kind"] == kind && entry["slug"] == slug }
    end

    test "a ship weapon carries its type data and durability as stats" do
      weapon = item("component", @weapon.slug)

      assert_equal "kbar_ballisticcannon_s2", weapon["scKey"]
      assert_equal "10-Series Greatsword Cannon", weapon["name"]
      assert_equal "weapon", weapon["category"]
      assert_equal "#{FRONTEND_ENDPOINT}/components/#{@weapon.slug}", weapon["url"]
      assert_equal @weapon.manufacturer.code, weapon.dig("manufacturer", "code")
      assert_equal({"fireRate" => 250, "speed" => 1196, "range" => 2703, "damagePerShot" => {"physical" => 72.99}}, weapon.dig("stats", "typeData"))
      assert_equal 850, weapon.dig("stats", "durability", "health")
      assert_equal 192, weapon.dig("stats", "durability", "mass")
    end

    test "stats leave out what names, describes or sells the item" do
      stats = item("component", @weapon.slug)["stats"]

      %w[id name slug description media availability manufacturer hidden retired createdAt updatedAt gradeLabel].each do |key|
        assert_not stats.key?(key), "#{key} should not be a stat"
      end
    end

    test "an armour piece carries its protection as stats, without label duplicates" do
      armor = item("equipment", @armor.slug)

      assert_equal "armor", armor["category"]
      assert_equal 25.0, armor.dig("stats", "damageReduction")
      assert_equal "-225 / 75 °C", armor.dig("stats", "temperatureRating")
      assert_equal 33_600.0, armor.dig("stats", "radiationProtection")
      assert_empty armor["stats"].keys.grep(/Label\z/)
    end

    test "a ship carries metrics, speeds and crew as stats" do
      ship = item("model", @ship.slug)

      assert_equal "#{FRONTEND_ENDPOINT}/ships/#{@ship.slug}", ship["url"]
      assert_equal 9000.0, ship.dig("stats", "metrics", "hullHealth")
      assert_equal 430_057.0, ship.dig("stats", "metrics", "mass")
      assert_equal 220.0, ship.dig("stats", "speeds", "scmSpeed")
      assert_equal 1240.0, ship.dig("stats", "speeds", "maxSpeed")
      assert_equal({"value" => 4}, ship.dig("stats", "crew"))
      assert_not ship["stats"].key?("pledgePrice")
      assert_not ship["stats"].key?("fociLabels")
    end

    test "a ship is pictured by its angled render, as the site search shows it" do
      @ship.store_image.attach(io: file_fixture("ship.jpg").open, filename: "ship.jpg", content_type: "image/jpeg")
      @ship.angled_view.attach(io: file_fixture("test.png").open, filename: "angled.png", content_type: "image/png")
      @ship.angled_view_colored.attach(io: file_fixture("test.png").open, filename: "angled_colored.png", content_type: "image/png")

      ship = item("model", @ship.slug)
      blob = @ship.angled_view_colored.blob

      assert_includes ship["image"], blob.signed_id
      assert_includes ship["thumb"], blob.signed_id
      assert_not_equal ship["image"], ship["thumb"]
    end

    test "a ship without a coloured render takes the plain one over its store image" do
      @ship.store_image.attach(io: file_fixture("ship.jpg").open, filename: "ship.jpg", content_type: "image/jpeg")
      @ship.angled_view.attach(io: file_fixture("test.png").open, filename: "angled.png", content_type: "image/png")

      ship = item("model", @ship.slug)

      assert_includes ship["image"], @ship.angled_view.blob.signed_id
      assert_includes ship["thumb"], @ship.angled_view.blob.signed_id
    end

    test "an item is pictured by its angled render over its store image" do
      [@weapon, @armor].each do |record|
        record.store_image.attach(io: file_fixture("image.jpg").open, filename: "store.jpg", content_type: "image/jpeg")
        record.angled_view.attach(io: file_fixture("test.png").open, filename: "angled.png", content_type: "image/png")
      end

      result = build

      [["component", @weapon], ["equipment", @armor]].each do |kind, record|
        entry = item(kind, record.slug, result)

        assert_includes entry["image"], record.angled_view.blob.signed_id
        assert_includes entry["thumb"], record.angled_view.blob.signed_id
      end
    end

    test "a ship without renders falls back to its store image" do
      @ship.store_image.attach(io: file_fixture("ship.jpg").open, filename: "ship.jpg", content_type: "image/jpeg")

      ship = item("model", @ship.slug)

      assert_includes ship["image"], @ship.store_image.blob.signed_id
      assert_includes ship["thumb"], @ship.store_image.blob.signed_id
    end

    test "an item without a picture has neither image nor thumb" do
      weapon = item("component", @weapon.slug)

      assert_not weapon.key?("image")
      assert_not weapon.key?("thumb")
    end

    test "leaves out paints, hidden components, hidden equipment and hidden ships" do
      paint = create(:component, name: "Some Livery", category: "paints")
      hidden = create(:component, :weapon, :hidden)
      hidden_equipment = create(:equipment, hidden: true)
      hidden_ship = create(:model, hidden: true)

      slugs = items.map { |entry| entry["slug"] }

      assert_not_includes slugs, paint.slug
      assert_not_includes slugs, hidden.slug
      assert_not_includes slugs, hidden_equipment.slug
      assert_not_includes slugs, hidden_ship.slug
      assert_includes slugs, @weapon.slug
    end

    test "the manifest names the gzipped bytes and counts the items" do
      result = build

      assert_equal 1, result.manifest[:schema]
      assert_equal "live", result.manifest[:channel]
      assert_equal ::ScData::Source.find("live").served.version, result.manifest[:gameVersion]
      assert_equal Digest::SHA256.hexdigest(result.items_gzip), result.manifest[:sha256]
      assert_equal "items.#{result.sha256.first(16)}.json.gz", result.manifest[:file]
      assert_equal items(result).size, result.manifest[:count]
    end

    test "an unchanged catalogue produces the same bytes, ordered by kind then slug" do
      first = build
      travel 1.hour
      second = build

      assert_equal first.sha256, second.sha256

      keys = items(second).map { |entry| [entry["kind"], entry["slug"]] }
      assert_equal keys.sort, keys
    end

    test "hardpoints are ordered by their content, not by how the database returned them" do
      export = Export.new("live")
      payload = {"hardpoints" => [{"name" => "b"}, {"name" => "a"}]}

      assert_equal [{"name" => "a"}, {"name" => "b"}], export.send(:deep_sort, payload)["hardpoints"]
    end

    test "refuses a channel that is not configured" do
      assert_raises(ArgumentError) { build("nope") }
    end
  end
end
