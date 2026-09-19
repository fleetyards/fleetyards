# frozen_string_literal: true

require "test_helper"

module ScData
  module Loader
    class CommoditiesLoaderTest < ActiveSupport::TestCase
      setup do
        Commodity.delete_all
        @loader = ::ScData::Loader::CommoditiesLoader.new
      end

      test "#all loads commodities from game files" do
        @loader.all

        assert_operator Commodity.count, :>=, 160

        sc_keys = Commodity.pluck(:sc_key)
        assert_equal sc_keys.uniq.size, sc_keys.size

        slugs = Commodity.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size
      end

      # The localization index is downcased while the game's type keys are camel
      # case, so a lookup that skips the downcase silently drops the label for
      # every multi-word type and leaves the single-word ones looking fine.
      test "every parsed commodity carries the label for its type" do
        parsed = @loader.load_items("commodities")

        assert_empty parsed.select { |commodity| commodity[:commodity_type_name].blank? }
          .map { |commodity| commodity[:sc_key] }
      end

      test "#all assigns a type to every commodity" do
        @loader.all

        assert_empty Commodity.where(commodity_type: nil).pluck(:name)
        assert_empty Commodity.where.not(commodity_type: Commodity::TYPES).pluck(:commodity_type)
      end

      test "#all resolves refined metals, ores and harvestables" do
        @loader.all

        assert_equal "metal", Commodity.find_by(sc_key: "items_commodities_gold")&.commodity_type
        assert_equal "metal", Commodity.find_by(sc_key: "items_commodities_iron_ore")&.commodity_type
        assert_equal "mineral", Commodity.find_by(sc_key: "items_commodities_janalite")&.commodity_type
        assert_equal "natural", Commodity.find_by(sc_key: "items_commodities_kopionhorn")&.commodity_type

        # The alloys are tagged both "alloy" and "metal" across crate records;
        # the bare commodity record settles it.
        assert_equal "alloy", Commodity.find_by(sc_key: "items_commodities_steel")&.commodity_type
      end

      test "#all is idempotent" do
        @loader.all
        count = Commodity.count

        assert_no_difference -> { Commodity.count } do
          @loader.all
        end

        assert_equal count, Commodity.count
      end

      # A new build leaves a dropped record on its old version, so
      # current_version filters it out. Re-importing the build we are already on
      # does not: the row keeps claiming it, and the picker keeps offering it.
      test "#all stops a dropped commodity claiming the build it is no longer in" do
        @loader.all

        retired = create(:commodity, sc_key: "items_commodities_gone", version: ScData::Source.version)

        @loader.all

        assert Commodity.exists?(retired.id), "the row has to stay for existing references"
        assert_nil retired.reload.version
        assert_not Commodity.current_version.exists?(retired.id)
      end

      test "#all leaves the commodities still in the export on the current build" do
        @loader.all
        @loader.all

        assert_operator Commodity.current_version.count, :>=, 160
      end

      # The game ships these as vectors and they stay vectors: the app serves
      # them inline instead of asking ActiveStorage for representations it
      # cannot make of one.
      test "#all attaches the icon the parser carried over" do
        @loader.all

        image = Commodity.find_by(sc_key: "items_commodities_gold").store_image

        assert_predicate image, :attached?
        assert_equal "inv_icon_gold.svg", image.filename.to_s
        assert_equal "image/svg+xml", image.content_type
        assert_not_predicate image, :representable?
      end

      # The gems, the drugs, the horns and the eggs: everything the game hands a
      # player a piece at a time. The eleven the recipes ask for are the reason
      # the fact is read at all, so they are named rather than counted.
      test "#all marks the commodities the game counts in pieces" do
        @loader.all

        crafting = %w[
          items_commodities_hadanite items_commodities_dolivine
          items_commodities_aphorite items_commodities_sadaryx
          items_commodities_beradom items_commodities_glacosite
          items_commodities_feynmaline items_commodities_janalite
          items_commodities_carinite items_commodities_saldynium_ore
          items_commodities_yormandi_eye
        ]

        assert_equal crafting.sort, Commodity.where(sc_key: crafting, counted: true).pluck(:sc_key).sort

        # Bulk is the other half of the claim: a material a recipe measures in
        # SCU must not start offering pieces.
        assert_not Commodity.find_by(sc_key: "items_commodities_iron").counted
        assert_not Commodity.find_by(sc_key: "items_commodities_gold").counted
      end

      # A fact only the row carried would leave the build saying "bulk" about a
      # commodity the row calls counted, and the build is what every reader
      # resolves through.
      test "#all writes counted onto the build as well as the row" do
        @loader.all

        commodity = Commodity.find_by(sc_key: "items_commodities_hadanite")

        assert commodity.build.counted
        assert commodity.counted
      end

      # The conversion between the two units. Every counted commodity states
      # one and no bulk one does, which is what keeps a hold-fill figure honest
      # once a position can be recorded in pieces.
      test "#all reads what one piece of a counted commodity takes up" do
        @loader.all

        assert_in_delta 0.001, Commodity.find_by(sc_key: "items_commodities_hadanite").piece_volume, 0.0000001
        assert_nil Commodity.find_by(sc_key: "items_commodities_iron").piece_volume

        assert_empty Commodity.where(counted: true, piece_volume: nil).pluck(:name)
        assert_empty Commodity.where(counted: false).where.not(piece_volume: nil).pluck(:name)
      end

      # Nine harvestables you pick and eat, the vent slug, and SLAM. Named
      # rather than counted, because the whole point of the fact is which ones.
      test "#all marks the commodities a player can eat or drink" do
        @loader.all

        assert_equal(
          ["Blue Bilva", "Golden Medmon", "Heart of the Woods", "Jumping Limes",
            "Lunes (Spiral Fruit)", "Oza", "Pitambu", "SLAM", "Sunset Berries",
            "Vent Slug"],
          Commodity.where(consumable: true).order(:name).pluck(:name)
        )
      end

      # SLAM's entities sit under entities/scitem/consumables, which is why the
      # parser reads a third path -- its crates say nothing about taking it.
      test "#all reads a consumable declared outside the commodity trees" do
        @loader.all

        assert_predicate Commodity.find_by(sc_key: "items_commodities_slam"), :consumable?
      end

      test "#all collects every size a commodity is packaged in" do
        @loader.all

        gold = Commodity.find_by(sc_key: "items_commodities_gold")

        assert_includes gold.container_sizes.map(&:to_f), 32.0
        assert_includes gold.container_sizes.map(&:to_f), 1.0
        assert_equal gold.container_sizes, gold.container_sizes.sort

        # The refuel and rearm goods are hauled in generic containers and have
        # no crate entity anywhere in the build.
        assert_empty Commodity.find_by(sc_key: "items_commodities_shipammo_size_1").container_sizes
      end

      # Resolved in a second pass: an ore is regularly read before the good it
      # refines into exists as a row.
      test "#all links an ore to the good it refines into" do
        @loader.all

        ore = Commodity.find_by(sc_key: "items_commodities_gold_ore")

        assert_equal "Gold", ore.refines_into&.name
        assert_nil Commodity.find_by(sc_key: "items_commodities_gold").refines_into
      end

      # Three of the construction material forms refine into the same good, so
      # the reverse side is a collection.
      test "#all links several raw forms to one refined good" do
        @loader.all

        refined = Commodity.find_by(sc_key: "items_commodities_constructionmaterials")

        assert_operator refined.refined_from.count, :>=, 3
      end

      test "#all keeps a commodity that already exists without an sc_key" do
        existing = create(:commodity, name: "Gold", sc_key: nil, commodity_type: nil)

        @loader.all

        existing.reload

        assert_equal "items_commodities_gold", existing.sc_key
        assert_equal "metal", existing.commodity_type
      end
    end
  end
end
