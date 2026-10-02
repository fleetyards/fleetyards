# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: fleet_squadron_memberships
#
#  id                     :uuid             not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  fleet_membership_id    :uuid             not null
#  fleet_squadron_id      :uuid             not null
#  fleet_squadron_role_id :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_memberships_on_fleet_membership_id      (fleet_membership_id)
#  index_fleet_squadron_memberships_on_fleet_squadron_role_id   (fleet_squadron_role_id)
#  index_fleet_squadron_memberships_on_squadron_and_membership  (fleet_squadron_id,fleet_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_membership_id => fleet_memberships.id)
#  fk_rails_...  (fleet_squadron_id => fleet_squadrons.id)
#  fk_rails_...  (fleet_squadron_role_id => fleet_squadron_roles.id)
#
class FleetSquadronMembershipTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @membership = create(:fleet_membership, :accepted, fleet: @fleet)
  end

  test "rejects a member of another fleet" do
    outsider = create(:fleet_membership, :accepted, fleet: create(:fleet))
    row = build(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: outsider)

    assert_not row.valid?
    assert_includes row.errors.attribute_names, :fleet_membership
  end

  test "rejects the same member twice in one squadron" do
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)
    duplicate = build(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :fleet_membership_id
  end

  # A member belongs to one squadron and to any number of teams. The rule
  # itself is `FleetSquadronTest::ExclusivityTest`; this is the shape of the
  # roster it leaves behind.
  test "allows one member on several teams of the same fleet" do
    other = create(:fleet_squadron, fleet: @fleet, team: true)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)

    assert_predicate build(:fleet_squadron_membership, fleet_squadron: other, fleet_membership: @membership), :valid?
  end

  test "starts a new member on the fleet's Member rank" do
    row = create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)

    assert_equal "member", row.fleet_squadron_role.key
    assert_equal @fleet.id, row.fleet_squadron_role.fleet_id
  end

  test "rejects a rank from another fleet" do
    foreign_rank = create(:fleet).fleet_squadron_roles.find_by!(key: "officer")
    row = build(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership, fleet_squadron_role: foreign_rank)

    assert_not row.valid?
    assert_includes row.errors.details[:fleet_squadron_role], {error: :not_in_fleet}
  end

  test "allows one Leader and one Co-Leader per squadron" do
    %w[leader co_leader].each do |key|
      rank = @fleet.fleet_squadron_roles.find_by!(key:)
      create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_squadron_role: rank)
      second = build(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_squadron_role: rank)

      assert_not second.valid?, "a second #{key} was accepted"
      assert_includes second.errors.details[:fleet_squadron_role], {error: :single_holder_taken, role: rank.name}
    end
  end

  test "allows a Leader in each squadron and any number of Officers" do
    leader = @fleet.fleet_squadron_roles.find_by!(key: "leader")
    officer = @fleet.fleet_squadron_roles.find_by!(key: "officer")
    other = create(:fleet_squadron, fleet: @fleet, team: true)

    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_squadron_role: leader)
    create_list(:fleet_squadron_membership, 2, fleet_squadron: @squadron, fleet_squadron_role: officer)

    assert_predicate build(:fleet_squadron_membership, fleet_squadron: other, fleet_squadron_role: leader), :valid?
  end

  test "keeps the Leader valid when another column changes" do
    leader = @fleet.fleet_squadron_roles.find_by!(key: "leader")
    row = create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_squadron_role: leader)

    assert row.update(created_at: 1.year.ago)
  end

  test "a Leader who left the fleet no longer holds the slot" do
    leader = @fleet.fleet_squadron_roles.find_by!(key: "leader")
    departed = create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_squadron_role: leader)
    departed.fleet_membership.discard!

    assert_predicate build(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_squadron_role: leader), :valid?
  end

  test "seeds the ranks of a fleet that has none" do
    @fleet.fleet_squadron_roles.delete_all

    row = create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)

    assert_equal "member", row.fleet_squadron_role.key
    assert_equal 4, @fleet.fleet_squadron_roles.count
  end
end
