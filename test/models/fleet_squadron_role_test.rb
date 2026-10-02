# frozen_string_literal: true

require "test_helper"

class FleetSquadronRoleTest < ActiveSupport::TestCase
  test "seeds the four ranks in order when a fleet is created" do
    fleet = create(:fleet)

    assert_equal %w[leader co_leader officer member], fleet.fleet_squadron_roles.map(&:key)
    assert_equal ["Squadron Leader", "Co-Leader", "Squadron Officer", "Member"], fleet.fleet_squadron_roles.map(&:name)
  end

  test "seeding twice leaves a renamed rank alone" do
    fleet = create(:fleet)
    fleet.fleet_squadron_roles.find_by!(key: "leader").update!(name: "Wing Commander")

    FleetSquadronRole.setup_defaults!(fleet)

    assert_equal 4, fleet.fleet_squadron_roles.count
    assert_equal "Wing Commander", fleet.fleet_squadron_roles.find_by!(key: "leader").name
  end

  test "a rename keeps the key and with it what the rank may do" do
    rank = create(:fleet).fleet_squadron_roles.find_by!(key: "officer")
    rank.update!(name: "Flight Lead")

    assert_equal "officer", rank.reload.key
    assert_predicate rank, :manages_members?
    assert_not rank.manages_ranks?
  end

  test "refuses to move a rank to another slot" do
    rank = create(:fleet).fleet_squadron_roles.find_by!(key: "officer")

    assert_raises(ActiveRecord::ReadonlyAttributeError) { rank.update(key: "leader") }
    assert_raises(ActiveRecord::ReadonlyAttributeError) { rank.update(position: 0) }
  end

  test "requires a name" do
    rank = create(:fleet).fleet_squadron_roles.find_by!(key: "member")

    assert_not rank.update(name: "")
  end

  test "maps each key to its privileges" do
    ranks = create(:fleet).fleet_squadron_roles.index_by(&:key)

    assert_equal %w[leader co_leader officer], ranks.values.select(&:manages_members?).map(&:key)
    assert_equal %w[leader co_leader], ranks.values.select(&:manages_ranks?).map(&:key)
    assert_equal %w[leader co_leader], ranks.values.select(&:single_holder?).map(&:key)
  end

  test "is destroyed with its fleet" do
    fleet = create(:fleet)
    squadron = create(:fleet_squadron, fleet:)
    create(:fleet_squadron_membership, fleet_squadron: squadron)

    assert_difference -> { FleetSquadronRole.count }, -4 do
      fleet.destroy!
    end
  end
end
