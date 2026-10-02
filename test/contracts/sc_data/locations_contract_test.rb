# frozen_string_literal: true

require "test_helper"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # Whether the real tree still nests the places the way the starmap parser
    # was written against. The fixture carries fifteen; these are the cases that
    # only show up across all 1,800 of them.
    class LocationsContractTest < ActiveSupport::TestCase
      include ScDataContractTree

      setup do
        require_real_tree

        GameMissionLocation.delete_all
        LocationBuild.delete_all
        Location.delete_all
      end

      test "the export still carries the starmap" do
        real_tree_loader(::ScData::Loader::LocationsLoader).all

        assert_operator Location.count, :>=, 1500

        slugs = Location.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size

        # Every place sits in a system, and only systems sit in none.
        assert_equal ["system"], Location.where(parent_id: nil).distinct.pluck(:kind)
        assert_equal 0, Location.where.not(kind: "system").where(system_id: nil).count

        filler = ::ScData::Parser::StarmapParser::FILLER_NAMES
        assert_equal 0, Location.where(name: [nil, "", *filler]).count

        levski = Location.find_by!(sc_key: "Nyx_Levski")
        assert_equal "Delamar", levski.parent.name
        assert_equal "Nyx", levski.map_parent.name

        admin_center = Location.find_by!(sc_key: "FloatingIsland_AdminCenter")
        assert_equal "Orison", admin_center.parent.name

        assert_equal "Ellis System", Location.find_by!(sc_key: "Ellis3").parent.name

        # A rest stop at its Lagrange point, the point on its planet.
        green_glade = Location.find_by!(sc_key: "RR_HUR_L1")
        assert_equal ["HUR L1", "Hurston"], [green_glade.parent.name, green_glade.parent.parent.name]
        assert_equal "Stanton", green_glade.map_parent.name
      end
    end
  end
end
