# frozen_string_literal: true

require "test_helper"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    class FactionsContractTest < ActiveSupport::TestCase
      include ScDataContractTree

      setup do
        require_real_tree

        FactionLadder.delete_all
        FactionBuild.delete_all
        Faction.delete_all
      end

      test "the export still carries the factions and their ladders" do
        real_tree_loader(::ScData::Loader::FactionsLoader).all

        assert_operator Faction.count, :>=, 30

        ladders = FactionLadder.all.to_a

        assert_empty ladders.select { |ladder| ladder.ranks.empty? }, "a ladder with no ranks is not one to show"
        assert_empty ladders.flat_map(&:ranks).pluck("name").grep(/PLACEHOLDER|\A@/), "a rank carried an unresolved name"

        foxwell = FactionBuild.find_by!(name: "Foxwell Enforcement").ladders.pluck(:name)

        assert_equal "Standing", foxwell.first
        assert_equal "Affinity", foxwell.last

        northrock = FactionBuild.find_by!(name: "Northrock Service Group").ladders.pluck(:name)

        assert_equal northrock.uniq, northrock
      end
    end
  end
end
