# frozen_string_literal: true

require "test_helper"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # The commodity questions that are about the export rather than the loader:
    # how much of the catalogue arrives, and which goods carry the facts the
    # crafting and hauling features are built on. See
    # test/support/sc_data_contract_tree.rb for why these cannot run on a pull
    # request.
    class CommoditiesContractTest < ActiveSupport::TestCase
      include ScDataContractTree

      setup do
        require_real_tree

        Commodity.delete_all
      end

      test "the export still carries the commodities catalogue" do
        real_tree_loader(::ScData::Loader::CommoditiesLoader).all

        assert_operator Commodity.count, :>=, 160

        sc_keys = Commodity.pluck(:sc_key)
        assert_equal sc_keys.uniq.size, sc_keys.size

        slugs = Commodity.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size

        assert_operator Commodity.current_version.count, :>=, 160

        assert_empty Commodity.where(commodity_type: nil).pluck(:name)
        assert_empty Commodity.where.not(commodity_type: Commodity::TYPES).pluck(:commodity_type)
      end

      # The gems, the drugs, the horns and the eggs: everything the game hands a
      # player a piece at a time. The eleven the recipes ask for are the reason
      # the fact is read at all, so they are named rather than counted.
      test "the export still counts the crafting materials in pieces" do
        real_tree_loader(::ScData::Loader::CommoditiesLoader).all

        crafting = %w[
          items_commodities_hadanite items_commodities_dolivine
          items_commodities_aphorite items_commodities_sadaryx
          items_commodities_beradom items_commodities_glacosite
          items_commodities_feynmaline items_commodities_janalite
          items_commodities_carinite items_commodities_saldynium_ore
          items_commodities_yormandi_eye
        ]

        assert_equal crafting.sort, Commodity.where(sc_key: crafting, counted: true).pluck(:sc_key).sort

        assert_empty Commodity.where(counted: true, piece_volume: nil).pluck(:name)
        assert_empty Commodity.where(counted: false).where.not(piece_volume: nil).pluck(:name)
      end

      # Nine harvestables you pick and eat, the vent slug, and SLAM. Named rather
      # than counted, because the whole point of the fact is which ones.
      test "the export still names the consumables" do
        real_tree_loader(::ScData::Loader::CommoditiesLoader).all

        assert_equal(
          ["Blue Bilva", "Golden Medmon", "Heart of the Woods", "Jumping Limes",
            "Lunes (Spiral Fruit)", "Oza", "Pitambu", "SLAM", "Sunset Berries",
            "Vent Slug"],
          Commodity.where(consumable: true).order(:name).pluck(:name)
        )
      end

      # Three of the construction material forms refine into the same good, so
      # the reverse side is a collection.
      test "the export still links several raw forms to one refined good" do
        real_tree_loader(::ScData::Loader::CommoditiesLoader).all

        refined = Commodity.find_by(sc_key: "items_commodities_constructionmaterials")

        assert_operator refined.refined_from.count, :>=, 3
      end
    end
  end
end
