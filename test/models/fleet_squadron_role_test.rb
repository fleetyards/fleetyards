# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: fleet_squadron_roles
#
#  id           :uuid             not null, primary key
#  default_rank :boolean          default(FALSE), not null
#  key          :string           not null
#  name         :string           not null
#  position     :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  fleet_id     :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_roles_on_fleet_id_and_key       (fleet_id,key) UNIQUE
#  index_fleet_squadron_roles_on_one_default_per_fleet  (fleet_id) UNIQUE WHERE default_rank
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
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

  test "seeds Member as the default and Leader and Co-Leader as permanent" do
    ranks = create(:fleet).fleet_squadron_roles.index_by(&:key)

    assert_equal %w[member], ranks.values.select(&:default_rank).map(&:key)
    assert_equal %w[leader co_leader], ranks.values.select(&:permanent?).map(&:key)
  end

  test "moving the default leaves exactly one" do
    fleet = create(:fleet)
    officer = fleet.fleet_squadron_roles.find_by!(key: "officer")

    officer.make_default!

    assert_equal %w[officer], fleet.fleet_squadron_roles.where(default_rank: true).pluck(:key)
    assert_equal officer, FleetSquadronRole.default_for(fleet)
  end

  test "the default cannot simply be cleared" do
    member = create(:fleet).fleet_squadron_roles.find_by!(key: "member")

    assert_not member.update(default_rank: false)
    assert_includes member.errors.details[:default_rank], {error: :required}
  end

  test "a permanent rank cannot be the default" do
    fleet = create(:fleet)
    leader = fleet.fleet_squadron_roles.find_by!(key: "leader")

    assert_raises(ActiveRecord::RecordInvalid) { leader.make_default! }
    assert_equal %w[member], fleet.fleet_squadron_roles.where(default_rank: true).pluck(:key)
  end
end
